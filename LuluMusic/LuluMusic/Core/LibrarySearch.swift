import Foundation

/// Lightweight track projection for search / list tests (F08).
struct LibraryTrackInfo: Equatable, Identifiable {
    var id: UUID
    var title: String
    var artist: String
    var venueTag: String
    var duration: TimeInterval

    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        venueTag: String = "",
        duration: TimeInterval = 0
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.venueTag = venueTag
        self.duration = duration
    }
}

enum LibrarySearch {
    static func filtered(_ tracks: [LibraryTrackInfo], query: String) -> [LibraryTrackInfo] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return tracks }
        return tracks.filter { matches($0, query: q) }
    }

    static func matches(_ track: LibraryTrackInfo, query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return true }
        return track.title.localizedCaseInsensitiveContains(q)
            || track.artist.localizedCaseInsensitiveContains(q)
            || track.venueTag.localizedCaseInsensitiveContains(q)
    }
}
