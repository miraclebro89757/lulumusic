import Foundation

struct ScrubSeekCommand: Equatable {
    var seconds: TimeInterval
    var shouldSeek: Bool
}

/// Maps a waveform / progress-bar x position onto AVPlayer seek seconds.
enum ScrubSeek {
    static func time(x: Double, width: Double, duration: TimeInterval) -> TimeInterval {
        command(x: x, width: width, duration: duration).seconds
    }

    static func command(x: Double, width: Double, duration: TimeInterval) -> ScrubSeekCommand {
        let span = TrackDuration.playbackSeconds(fromRaw: duration)
        guard span > 0, width.isFinite, width > 0, x.isFinite else {
            return ScrubSeekCommand(seconds: 0, shouldSeek: false)
        }
        let fraction = min(1, max(0, x / width))
        return ScrubSeekCommand(seconds: span * fraction, shouldSeek: true)
    }
}
