import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(PlayerEngine.self) private var player
    @Environment(LibraryService.self) private var library
    @Query(sort: \Track.dateAdded, order: .reverse) private var tracks: [Track]
    @State private var search = ""
    @State private var showFiles = false
    @State private var venueDraft = ""
    @State private var venueTrack: Track?

    var filtered: [Track] {
        let infos = tracks.map(\.asSearchInfo)
        let ids = Set(LibrarySearch.filtered(infos, query: search).map(\.id))
        return tracks.filter { ids.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if tracks.isEmpty {
                    EmptyLibraryView()
                } else {
                    List {
                        columnHeader
                        ForEach(filtered) { track in
                            TrackRow(track: track, isCurrent: player.current?.id == track.id, isPlaying: player.isPlaying)
                                .contentShape(Rectangle())
                                .onTapGesture { play(track) }
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
                                        venueTrack = track
                                        venueDraft = track.venueTag
                                    } label: {
                                        Label(L10n.setVenue, systemImage: "mappin.and.ellipse")
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
            .navigationTitle(L10n.appName)
            .searchable(text: $search, prompt: L10n.searchPrompt)
            .task { await library.importSharedDocumentsIfNeeded() }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showFiles = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                    }
                    .accessibilityLabel(L10n.importFilesButton)

                    NavigationLink {
                        WebUploadView()
                    } label: {
                        Image(systemName: "wifi")
                    }
                    .accessibilityLabel(L10n.importWebButton)
                }
            }
            .sheet(isPresented: $showFiles) {
                AudioDocumentPicker { urls in
                    showFiles = false
                    let accepted = IncomingTransfer.importableURLs(from: urls)
                    Task { await library.importFiles(from: accepted, source: .files) }
                }
                .ignoresSafeArea()
            }
            .alert(L10n.setVenue, isPresented: Binding(
                get: { venueTrack != nil },
                set: { if !$0 { venueTrack = nil } }
            )) {
                TextField(L10n.venuePlaceholder, text: $venueDraft)
                Button(L10n.done) {
                    if let track = venueTrack {
                        library.updateVenueTag(track, venueTag: venueDraft)
                    }
                    venueTrack = nil
                }
                Button(L10n.cancel, role: .cancel) { venueTrack = nil }
            }
        }
    }

    private var columnHeader: some View {
        HStack {
            Text(L10n.songTitle).frame(maxWidth: .infinity, alignment: .leading)
            Text("歌手").frame(width: 72, alignment: .leading)
            Text(L10n.venueTag).frame(width: 56, alignment: .leading)
            Text("时长").frame(width: 44, alignment: .trailing)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .accessibilityHidden(true)
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
        HStack(spacing: 10) {
            ArtworkView(url: track.resolvedArtworkURL, seed: track.title + track.artist, cornerRadius: 6)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if isCurrent {
                        Image(systemName: isPlaying ? "waveform" : "pause.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.accentColor)
                    }
                    Text(track.title)
                        .font(.body.weight(isCurrent ? .semibold : .regular))
                        .foregroundStyle(isCurrent ? Color.accentColor : .primary)
                        .lineLimit(1)
                }
                Text(track.artist)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(track.venueTag.isEmpty ? "—" : track.venueTag)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 56, alignment: .leading)

            Text(TimeFormat.duration(track.duration))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .trailing)
        }
        .padding(.vertical, 2)
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
