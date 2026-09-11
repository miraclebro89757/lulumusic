import AVFoundation
import Foundation
import MediaPlayer
import SwiftData
import UIKit

struct ImportOutcome: Sendable {
    var imported: [UUID] = []
    var failed: [String] = []
    var skippedProtected: Int = 0
}

enum LibraryError: LocalizedError {
    case cannotOpen
    case copyFailed
    case protected
    case unsupported

    var errorDescription: String? {
        switch self {
        case .cannotOpen: return L10n.cannotOpenFile
        case .copyFailed: return L10n.importFailedGeneric
        case .protected: return L10n.skippedDRM
        case .unsupported: return L10n.unsupportedFormat
        }
    }
}

@MainActor
@Observable
final class LibraryService {
    private let container: ModelContainer

    var isImporting = false
    var lastOutcome: ImportOutcome?
    var bannerMessage: String?
    private var importDepth = 0

    init(container: ModelContainer) {
        self.container = container
        try? LibraryPaths.ensureDirectories()
    }

    private var context: ModelContext { container.mainContext }

    @discardableResult
    func importFile(from inboundURL: URL, source: ImportSource, originalName: String? = nil) async throws -> Track {
        beginImport()
        defer { endImport() }

        let accessed = inboundURL.startAccessingSecurityScopedResource()
        defer {
            if accessed { inboundURL.stopAccessingSecurityScopedResource() }
        }

        try LibraryPaths.ensureDirectories()

        let ext = inboundURL.pathExtension.isEmpty ? "m4a" : inboundURL.pathExtension.lowercased()
        guard ImportFormatAllowlist.isAllowed(fileName: inboundURL.lastPathComponent)
                || ImportFormatAllowlist.allowedExtensions.contains(ext) else {
            throw LibraryError.unsupported
        }

        let id = UUID()
        let fileName = "\(id.uuidString).\(ext)"
        let dest = LibraryPaths.musicDirectory.appendingPathComponent(fileName)
        let displayName = originalName ?? inboundURL.lastPathComponent

        do {
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.copyItem(at: inboundURL, to: dest)
        } catch {
            throw LibraryError.copyFailed
        }

        let meta = await MetadataExtractor.extract(from: dest, fallbackName: displayName)
        var artworkPath: String?
        if let jpeg = meta.artworkJPEG {
            let artName = "\(id.uuidString).jpg"
            let artURL = LibraryPaths.artworkDirectory.appendingPathComponent(artName)
            try? jpeg.write(to: artURL, options: .atomic)
            artworkPath = "Artwork/\(artName)"
        }

        let track = Track(
            id: id,
            title: meta.title,
            artist: meta.artist,
            album: meta.album,
            duration: TrackDuration.playbackSeconds(fromRaw: meta.duration),
            relativeFilePath: "Music/\(fileName)",
            relativeArtworkPath: artworkPath,
            source: source,
            originalFileName: displayName
        )
        context.insert(track)
        try context.save()
        return track
    }

    func importFiles(from urls: [URL], source: ImportSource) async -> ImportOutcome {
        var outcome = ImportOutcome()
        beginImport()
        defer { endImport() }

        for url in urls {
            do {
                let track = try await importFile(from: url, source: source)
                outcome.imported.append(track.id)
            } catch LibraryError.protected {
                outcome.skippedProtected += 1
                outcome.failed.append(url.lastPathComponent)
            } catch {
                outcome.failed.append(url.lastPathComponent)
            }
        }
        lastOutcome = outcome
        bannerMessage = Self.summary(from: outcome)
        return outcome
    }

    func importMediaItems(_ items: [MPMediaItem]) async -> ImportOutcome {
        var outcome = ImportOutcome()
        beginImport()
        defer { endImport() }

        for item in items {
            do {
                let track = try await importMediaItem(item)
                outcome.imported.append(track.id)
            } catch LibraryError.protected {
                outcome.skippedProtected += 1
                if let title = item.title { outcome.failed.append(title) }
            } catch {
                outcome.failed.append(item.title ?? L10n.unknownTitle)
            }
        }
        lastOutcome = outcome
        bannerMessage = Self.summary(from: outcome)
        return outcome
    }

    func delete(_ track: Track, player: PlayerEngine) throws {
        player.removeFromQueue(trackID: track.id)
        let fileURL = track.resolvedFileURL
        let artURL = track.resolvedArtworkURL
        context.delete(track)
        try context.save()
        try? FileManager.default.removeItem(at: fileURL)
        if let artURL {
            try? FileManager.default.removeItem(at: artURL)
        }
    }

    func track(id: UUID) -> Track? {
        let descriptor = FetchDescriptor<Track>(predicate: #Predicate { $0.id == id })
        return try? context.fetch(descriptor).first
    }

    /// Files dropped via Finder / iTunes File Sharing land in Documents.
    func importSharedDocumentsIfNeeded() async {
        let fm = FileManager.default
        guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let inbox = docs.appendingPathComponent("Inbox", isDirectory: true)
        var candidates: [URL] = []
        for directory in [docs, inbox] {
            guard let items = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else {
                continue
            }
            candidates.append(contentsOf: items.filter { url in
                var isDir: ObjCBool = false
                guard fm.fileExists(atPath: url.path, isDirectory: &isDir), !isDir.boolValue else { return false }
                return ImportFormatAllowlist.isAllowed(fileName: url.lastPathComponent)
            })
        }
        guard !candidates.isEmpty else { return }
        var importedURLs: [URL] = []
        for url in candidates {
            do {
                _ = try await importFile(from: url, source: .share)
                importedURLs.append(url)
            } catch {
                continue
            }
        }
        for url in importedURLs {
            try? fm.removeItem(at: url)
        }
        if !importedURLs.isEmpty {
            bannerMessage = String(format: L10n.importedCountFormat, importedURLs.count)
        }
    }

    func allTracks() -> [Track] {
        let descriptor = FetchDescriptor<Track>(sortBy: [SortDescriptor(\.dateAdded, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    private func beginImport() {
        importDepth += 1
        isImporting = true
    }

    private func endImport() {
        importDepth = max(0, importDepth - 1)
        isImporting = importDepth > 0
    }

    private func importMediaItem(_ item: MPMediaItem) async throws -> Track {
        guard let assetURL = item.assetURL else { throw LibraryError.protected }

        try LibraryPaths.ensureDirectories()
        let id = UUID()
        let dest = LibraryPaths.musicDirectory.appendingPathComponent("\(id.uuidString).m4a")

        if assetURL.isFileURL {
            try FileManager.default.copyItem(at: assetURL, to: dest)
        } else {
            try await exportAsset(from: assetURL, to: dest)
        }

        var title = item.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if title.isEmpty { title = L10n.unknownTitle }
        let artist = item.artist?.isEmpty == false ? (item.artist ?? L10n.unknownArtist) : L10n.unknownArtist
        let album = item.albumTitle?.isEmpty == false ? (item.albumTitle ?? L10n.unknownAlbum) : L10n.unknownAlbum
        let duration = item.playbackDuration

        var artworkPath: String?
        if let image = item.artwork?.image(at: CGSize(width: 600, height: 600)),
           let jpeg = image.jpegData(compressionQuality: 0.86) {
            let artName = "\(id.uuidString).jpg"
            try? jpeg.write(to: LibraryPaths.artworkDirectory.appendingPathComponent(artName), options: .atomic)
            artworkPath = "Artwork/\(artName)"
        } else {
            let meta = await MetadataExtractor.extract(from: dest, fallbackName: title)
            if let jpeg = meta.artworkJPEG {
                let artName = "\(id.uuidString).jpg"
                try? jpeg.write(to: LibraryPaths.artworkDirectory.appendingPathComponent(artName), options: .atomic)
                artworkPath = "Artwork/\(artName)"
            }
        }

        let track = Track(
            id: id,
            title: title,
            artist: artist,
            album: album,
            duration: {
                if duration > 0 { return TrackDuration.playbackSeconds(fromRaw: duration) }
                let asset = TrackDuration.preciseAsset(url: dest)
                if let cm = try? await asset.load(.duration) {
                    return TrackDuration.playbackSeconds(from: cm)
                }
                return 0
            }(),
            relativeFilePath: "Music/\(id.uuidString).m4a",
            relativeArtworkPath: artworkPath,
            source: .appleMusic,
            originalFileName: title
        )
        context.insert(track)
        try context.save()
        return track
    }

    private func exportAsset(from source: URL, to destination: URL) async throws {
        let asset = AVURLAsset(url: source)
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw LibraryError.protected
        }
        session.outputURL = destination
        session.outputFileType = .m4a
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            session.exportAsynchronously {
                continuation.resume()
            }
        }
        guard session.status == .completed else {
            throw LibraryError.protected
        }
    }

    private static func summary(from outcome: ImportOutcome) -> String {
        var parts: [String] = []
        if !outcome.imported.isEmpty {
            parts.append(String(format: L10n.importedCountFormat, outcome.imported.count))
        }
        if outcome.skippedProtected > 0 {
            parts.append("\(L10n.skippedDRM) (\(outcome.skippedProtected))")
        }
        if !outcome.failed.isEmpty && outcome.skippedProtected == 0 {
            parts.append("\(L10n.importFailed): \(outcome.failed.count)")
        }
        return parts.isEmpty ? L10n.importFailed : parts.joined(separator: " · ")
    }

    func updateVenueTag(_ track: Track, venueTag: String) {
        track.venueTag = venueTag.trimmingCharacters(in: .whitespacesAndNewlines)
        try? context.save()
    }

    func updateLastPosition(trackID: UUID, positionMS: Int) {
        guard let track = track(id: trackID) else { return }
        track.lastPositionMS = max(0, positionMS)
        try? context.save()
    }

    static let allowedExtensions: Set<String> = ImportFormatAllowlist.allowedExtensions
}
