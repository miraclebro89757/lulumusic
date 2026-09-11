import Foundation

/// Local-only liked tracks (A02). No sync, no social, no liked Tab.
@Observable
final class FavoriteStore {
    static let key = "lovesong.favoriteTrackIDs.v1"

    private let defaults: UserDefaults
    private var ids: Set<String>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let stored = defaults.array(forKey: Self.key) as? [String] {
            ids = Set(stored)
        } else {
            ids = []
        }
    }

    func isLiked(_ id: UUID) -> Bool {
        ids.contains(id.uuidString)
    }

    @discardableResult
    func toggle(_ id: UUID) -> Bool {
        setLiked(id, !isLiked(id))
        return isLiked(id)
    }

    func setLiked(_ id: UUID, _ liked: Bool) {
        if liked {
            ids.insert(id.uuidString)
        } else {
            ids.remove(id.uuidString)
        }
        persist()
    }

    private func persist() {
        defaults.set(Array(ids).sorted(), forKey: Self.key)
    }
}
