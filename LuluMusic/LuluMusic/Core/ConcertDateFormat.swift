import Foundation

enum ConcertDateFormat {
    private static let calendar = Calendar(identifier: .gregorian)

    static func full(_ date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return String(format: "%04d.%02d.%02d", year, month, day)
    }

    static func short(_ date: Date) -> String {
        let parts = calendar.dateComponents([.month, .day], from: date)
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return "\(month).\(day)"
    }
}
