import AVFoundation
import Foundation

/// Canonical track length in **seconds** for library rows, player chrome, and seek.
enum TrackDuration {
    /// Live / album cuts in this app stay under six hours; bigger magnitudes are ms ticks.
    static let plausibleMaxSeconds: TimeInterval = 6 * 3600

    static func playbackSeconds(fromRaw raw: TimeInterval) -> TimeInterval {
        guard raw.isFinite, raw >= 0 else { return 0 }
        if raw > plausibleMaxSeconds {
            let asMilliseconds = raw / 1000
            if asMilliseconds > 0, asMilliseconds <= plausibleMaxSeconds {
                return asMilliseconds
            }
        }
        return raw
    }

    static func playbackSeconds(from cm: CMTime) -> TimeInterval {
        guard cm.isNumeric, !cm.isIndefinite else { return 0 }
        let seconds = cm.seconds
        guard seconds.isFinite, seconds >= 0 else { return 0 }
        return playbackSeconds(fromRaw: seconds)
    }

    static func preciseAsset(url: URL) -> AVURLAsset {
        AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
    }

    /// Prefer a known MediaItem / metadata length; otherwise load precise asset timing.
    static func resolvedPlaybackSeconds(raw: TimeInterval, fileURL: URL) async -> TimeInterval {
        let known = playbackSeconds(fromRaw: raw)
        if known > 0 { return known }
        let asset = preciseAsset(url: fileURL)
        guard let cm = try? await asset.load(.duration) else { return 0 }
        return playbackSeconds(from: cm)
    }
}
