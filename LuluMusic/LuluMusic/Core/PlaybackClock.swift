import Foundation

enum PlaybackClockSource: Equatable {
    case avPlayerCurrentTime
    case systemDate
}

/// Converts AVPlayer `currentTime` seconds into millisecond anchors for UI + danmaku.
enum PlaybackClock {
    static let source: PlaybackClockSource = .avPlayerCurrentTime

    static func milliseconds(fromPlayerSeconds seconds: TimeInterval) -> Int {
        guard seconds.isFinite, seconds >= 0 else { return 0 }
        return Int((seconds * 1000).rounded())
    }
}
