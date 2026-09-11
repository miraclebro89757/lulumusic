import SwiftUI

enum AppTheme {
    static var accent: Color { LoveSongTheme.spotlight }
    static var stageBlack: Color { LoveSongTheme.stageBackground }

    static func hashGradient(for seed: String) -> LinearGradient {
        LoveSongTheme.hashGradient(for: seed)
    }
}

enum TimeFormat {
    static func duration(_ time: TimeInterval) -> String {
        guard time.isFinite, time >= 0 else { return L10n.durationUnknown }
        let seconds = TrackDuration.playbackSeconds(fromRaw: time)
        let total = Int(seconds.rounded(.towardZero))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

enum RelativeDateFormat {
    static func string(from date: Date, now: Date = Date()) -> String {
        let seconds = Int(now.timeIntervalSince(date))
        if seconds < 60 { return L10n.justNow }
        if seconds < 3600 { return "\(seconds / 60) \(L10n.minutesAgo)" }
        if seconds < 86_400 { return "\(seconds / 3600) \(L10n.hoursAgo)" }
        return "\(seconds / 86_400) \(L10n.daysAgo)"
    }
}
