import AVFoundation
import Foundation
import UIKit

struct ExtractedMetadata: Sendable {
    var title: String
    var artist: String
    var album: String
    var duration: TimeInterval
    var artworkJPEG: Data?
}

enum MetadataExtractor {
    static func extract(from url: URL, fallbackName: String) async -> ExtractedMetadata {
        let asset = TrackDuration.preciseAsset(url: url)
        var title = sanitizedTitle(from: fallbackName)
        var artist = L10n.unknownArtist
        var album = L10n.unknownAlbum
        var artwork: Data?
        var duration: TimeInterval = 0

        do {
            let cmDuration = try await asset.load(.duration)
            duration = TrackDuration.playbackSeconds(from: cmDuration)
        } catch {
            duration = 0
        }
        if duration <= 0 {
            duration = await audioTrackDuration(from: asset)
        }
        if duration <= 0 {
            duration = await id3TLENDuration(from: asset)
        }

        do {
            let metadata = try await asset.load(.commonMetadata)
            for item in metadata {
                guard let key = item.commonKey else { continue }
                switch key {
                case .commonKeyTitle:
                    if let value = try? await item.load(.stringValue), !value.isEmpty {
                        title = value
                    }
                case .commonKeyArtist:
                    if let value = try? await item.load(.stringValue), !value.isEmpty {
                        artist = value
                    }
                case .commonKeyAlbumName:
                    if let value = try? await item.load(.stringValue), !value.isEmpty {
                        album = value
                    }
                case .commonKeyArtwork:
                    if let data = try? await item.load(.dataValue) {
                        artwork = normalizedJPEG(from: data)
                    }
                default:
                    break
                }
            }
        } catch {
            // Keep filename fallbacks.
        }

        return ExtractedMetadata(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            artworkJPEG: artwork
        )
    }

    private static func audioTrackDuration(from asset: AVURLAsset) async -> TimeInterval {
        guard let tracks = try? await asset.loadTracks(withMediaType: .audio),
              let track = tracks.first,
              let range = try? await track.load(.timeRange) else { return 0 }
        return TrackDuration.playbackSeconds(from: range.duration)
    }

    /// ID3 TLEN is milliseconds as a numeric string.
    private static func id3TLENDuration(from asset: AVURLAsset) async -> TimeInterval {
        guard let items = try? await asset.load(.metadata) else { return 0 }
        let lengths = AVMetadataItem.metadataItems(from: items, filteredByIdentifier: .id3MetadataLength)
        for item in lengths {
            if let string = try? await item.load(.stringValue),
               let millis = Double(string.trimmingCharacters(in: .whitespacesAndNewlines)),
               millis > 0 {
                return TrackDuration.playbackSeconds(fromRaw: millis / 1000)
            }
            if let number = try? await item.load(.numberValue) {
                let millis = number.doubleValue
                if millis > 0 {
                    return TrackDuration.playbackSeconds(fromRaw: millis / 1000)
                }
            }
        }
        return 0
    }

    static func sanitizedTitle(from fileName: String) -> String {
        let base = URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent
        let trimmed = base.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? L10n.unknownTitle : trimmed
    }

    private static func normalizedJPEG(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return data }
        let maxEdge: CGFloat = 1024
        let size = image.size
        let scale = min(1, maxEdge / max(size.width, size.height))
        let target = CGSize(width: max(1, size.width * scale), height: max(1, size.height * scale))
        let renderer = UIGraphicsImageRenderer(size: target)
        let rendered = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return rendered.jpegData(compressionQuality: 0.86)
    }
}
