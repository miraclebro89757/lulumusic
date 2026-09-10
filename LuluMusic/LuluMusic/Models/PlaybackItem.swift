import Foundation

/// Snapshot used by the player so playback does not depend on a live SwiftData object.
struct PlaybackItem: Identifiable, Hashable, Sendable {
    let id: UUID
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let fileURL: URL
    let artworkURL: URL?

    init(track: Track) {
        id = track.id
        title = track.title
        artist = track.artist
        album = track.album
        duration = track.duration
        fileURL = track.resolvedFileURL
        artworkURL = track.resolvedArtworkURL
    }
}
