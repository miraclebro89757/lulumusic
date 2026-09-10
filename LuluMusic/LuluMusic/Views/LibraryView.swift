import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(PlayerEngine.self) private var player
    @Environment(LibraryService.self) private var library
    @Query(sort: \Track.dateAdded, order: .reverse) private var tracks: [Track]
    @State private var search = ""

    var filtered: [Track] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return tracks }
        return tracks.filter {
            $0.title.localizedCaseInsensitiveContains(q)
                || $0.artist.localizedCaseInsensitiveContains(q)
                || $0.album.localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if tracks.isEmpty {
                    EmptyLibraryView()
                } else {
                    List {
                        ForEach(filtered) { track in
                            TrackRow(track: track, isCurrent: player.current?.id == track.id, isPlaying: player.isPlaying)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    play(track)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        try? library.delete(track, player: player)
                                    } label: {
                                        Label(L10n.delete, systemImage: "trash")
                                    }
                                }
                                .contextMenu {
                                    Button {
                                        play(track)
                                    } label: {
                                        Label(L10n.playNow, systemImage: "play.fill")
                                    }
                                    Button {
                                        player.enqueueNext(track)
                                    } label: {
                                        Label(L10n.playNext, systemImage: "text.line.first.and.arrowtriangle.forward")
                                    }
                                    Button(role: .destructive) {
                                        try? library.delete(track, player: player)
                                    } label: {
                                        Label(L10n.delete, systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(L10n.tabLibrary)
            .searchable(text: $search, prompt: L10n.searchPrompt)
            .task {
                await library.importSharedDocumentsIfNeeded()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(tracks.count) \(L10n.tracksUnit)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func play(_ track: Track) {
        if let idx = tracks.firstIndex(where: { $0.id == track.id }) {
            player.play(tracks: tracks, startAt: idx)
        } else {
            player.playNow(track, library: tracks)
        }
    }
}

struct TrackRow: View {
    let track: Track
    var isCurrent: Bool
    var isPlaying: Bool

    var body: some View {
        HStack(spacing: 12) {
            ArtworkView(url: track.resolvedArtworkURL, seed: track.title + track.artist, cornerRadius: 8)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.body.weight(isCurrent ? .semibold : .regular))
                    .foregroundStyle(isCurrent ? Color.accentColor : .primary)
                    .lineLimit(1)
                Text("\(track.artist) · \(track.album)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                if isCurrent {
                    Image(systemName: isPlaying ? "waveform" : "pause.fill")
                        .foregroundStyle(Color.accentColor)
                        .font(.caption)
                }
                Text(TimeFormat.duration(track.duration))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmptyLibraryView: View {
    var body: some View {
        ContentUnavailableView {
            Label(L10n.emptyLibraryTitle, systemImage: "music.note.house")
        } description: {
            Text(L10n.emptyLibrarySubtitle)
        }
        .padding()
    }
}
