import Foundation

/// Live Tab visible-set: comments whose timestamp has already been reached,
/// newest-in-time last, capped at 50. Seek rebuilds by recomputing from the catalog.
enum LiveDanmakuWindow {
    static let maxVisible = 50

    static func visible(
        records: [DanmakuRecord],
        nowMS: Int,
        limit: Int = maxVisible
    ) -> [DanmakuRecord] {
        let triggered = records
            .filter { $0.timestampMS <= nowMS }
            .sorted { lhs, rhs in
                if lhs.timestampMS != rhs.timestampMS {
                    return lhs.timestampMS < rhs.timestampMS
                }
                if lhs.createdAt != rhs.createdAt {
                    return lhs.createdAt < rhs.createdAt
                }
                return lhs.id.uuidString < rhs.id.uuidString
            }
        guard triggered.count > limit else { return triggered }
        return Array(triggered.suffix(limit))
    }
}
