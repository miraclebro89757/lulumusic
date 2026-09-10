import Foundation
import SwiftData

@Model
final class Track {
    @Attribute(.unique) var id: UUID
    var title: String
    var artist: String
    var album: String
    var duration: Double
    var relativeFilePath: String
    var relativeArtworkPath: String?
    var dateAdded: Date
    var sourceRaw: String
    var originalFileName: String
    var venueTag: String
    var lastPositionMS: Int

    var filePath: String { relativeFilePath }
    var coverArt: String? { relativeArtworkPath }
    var addedAt: Date { dateAdded }

    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        album: String,
        duration: Double,
        relativeFilePath: String,
        relativeArtworkPath: String? = nil,
        dateAdded: Date = Date(),
        source: ImportSource,
        originalFileName: String,
        venueTag: String = "",
        lastPositionMS: Int = 0
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.relativeFilePath = relativeFilePath
        self.relativeArtworkPath = relativeArtworkPath
        self.dateAdded = dateAdded
        self.sourceRaw = source.rawValue
        self.originalFileName = originalFileName
        self.venueTag = venueTag
        self.lastPositionMS = lastPositionMS
    }

    var asSearchInfo: LibraryTrackInfo {
        LibraryTrackInfo(id: id, title: title, artist: artist, venueTag: venueTag, duration: duration)
    }

    var source: ImportSource {
        ImportSource(rawValue: sourceRaw) ?? .files
    }

    var resolvedFileURL: URL {
        LibraryPaths.applicationSupport.appendingPathComponent(relativeFilePath)
    }

    var resolvedArtworkURL: URL? {
        guard let relativeArtworkPath else { return nil }
        return LibraryPaths.applicationSupport.appendingPathComponent(relativeArtworkPath)
    }

    var existsOnDisk: Bool {
        FileManager.default.fileExists(atPath: resolvedFileURL.path)
    }
}

enum LibraryPaths {
    static var applicationSupport: URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let folder = root.appendingPathComponent("LuluMusic", isDirectory: true)
        return folder
    }

    static var musicDirectory: URL {
        applicationSupport.appendingPathComponent("Music", isDirectory: true)
    }

    static var artworkDirectory: URL {
        applicationSupport.appendingPathComponent("Artwork", isDirectory: true)
    }

    static var uploadTempDirectory: URL {
        applicationSupport.appendingPathComponent("Uploads", isDirectory: true)
    }

    static func ensureDirectories() throws {
        let fm = FileManager.default
        try fm.createDirectory(at: musicDirectory, withIntermediateDirectories: true)
        try fm.createDirectory(at: artworkDirectory, withIntermediateDirectories: true)
        try fm.createDirectory(at: uploadTempDirectory, withIntermediateDirectories: true)
    }
}
