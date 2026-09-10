import SwiftUI

enum AppTheme {
    static let accent = Color.accentColor
    static let rose = Color(red: 0.95, green: 0.38, blue: 0.42)
    static let amber = Color(red: 0.95, green: 0.72, blue: 0.35)
    static let stageBlack = Color(red: 0.04, green: 0.03, blue: 0.05)
    static let stagePurple = Color(red: 0.22, green: 0.08, blue: 0.28)

    static var concertBackground: LinearGradient {
        LinearGradient(
            colors: [stagePurple, stageBlack, Color.black],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var artworkGradient: LinearGradient {
        LinearGradient(
            colors: [stagePurple, rose],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func hashGradient(for seed: String) -> LinearGradient {
        var hasher = Hasher()
        hasher.combine(seed)
        let value = abs(hasher.finalize())
        let hue1 = Double(value % 360) / 360.0
        let hue2 = Double((value / 7) % 360) / 360.0
        return LinearGradient(
            colors: [
                Color(hue: hue1, saturation: 0.55, brightness: 0.45),
                Color(hue: hue2, saturation: 0.70, brightness: 0.62)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

enum TimeFormat {
    static func duration(_ time: TimeInterval) -> String {
        guard time.isFinite, time >= 0 else { return L10n.durationUnknown }
        let total = Int(time.rounded(.towardZero))
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
