import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(PlayerEngine.self) private var player
    @Environment(LibraryService.self) private var library
    @Query(sort: \Track.dateAdded, order: .reverse) private var tracks: [Track]
    @State private var search = ""
    @State private var showFiles = false
    @State private var showWifi = false
    @State private var venueDraft = ""
    @State private var venueTrack: Track?

    var filtered: [Track] {
        let infos = tracks.map(\.asSearchInfo)
        let ids = Set(LibrarySearch.filtered(infos, query: search).map(\.id))
        return tracks.filter { ids.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LoveSongTheme.stageFill
                VStack(spacing: 0) {
                    StageSearchField(text: $search)
                        .padding(.horizontal, LoveSongTheme.Space.screen)
                        .padding(.top, 8)
                        .padding(.bottom, 10)

                    if !tracks.isEmpty {
                        QuietImportBar(
                            onFiles: { showFiles = true },
                            onWifi: { showWifi = true }
                        )
                        .padding(.horizontal, LoveSongTheme.Space.screen)
                        .padding(.bottom, 8)
                    }

                    if tracks.isEmpty {
                        EmptyLibraryView(
                            onFiles: { showFiles = true },
                            onWifi: { showWifi = true }
                        )
                    } else {
                        List {
                            ForEach(filtered) { track in
                                TrackRow(
                                    track: track,
                                    isCurrent: player.current?.id == track.id,
                                    isPlaying: player.isPlaying
                                )
                                .contentShape(Rectangle())
                                .onTapGesture { play(track) }
                                .listRowBackground(Color.clear)
                                .listRowSeparatorTint(LoveSongTheme.separator)
                                .listRowInsets(EdgeInsets(top: 8, leading: LoveSongTheme.Space.screen, bottom: 8, trailing: LoveSongTheme.Space.screen))
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
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle(L10n.tabLibrary)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(LoveSongTheme.stageBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task { await library.importSharedDocumentsIfNeeded() }
            .navigationDestination(isPresented: $showWifi) {
                WebUploadView()
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
            ArtworkView(
                url: track.resolvedArtworkURL,
                seed: track.title + track.artist,
                cornerRadius: 12
            )
            .frame(width: LoveSongTheme.Space.rowCover, height: LoveSongTheme.Space.rowCover)
            .shadow(color: .black.opacity(0.35), radius: 8, y: 3)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    if isCurrent {
                        Image(systemName: isPlaying ? "waveform" : "pause.fill")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(LoveSongTheme.spotlight)
                    }
                    Text(track.title)
                        .font(LoveSongTheme.Font.rowTitle)
                        .foregroundStyle(isCurrent ? LoveSongTheme.spotlight : LoveSongTheme.textPrimary)
                        .lineLimit(1)
                }
                HStack(spacing: 8) {
                    Text(track.artist)
                        .font(LoveSongTheme.Font.rowCaption)
                        .foregroundStyle(LoveSongTheme.textSecondary)
                        .lineLimit(1)
                    if !track.venueTag.isEmpty {
                        VenueChip(text: track.venueTag, compact: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(TimeFormat.duration(track.duration))
                .font(LoveSongTheme.Font.time)
                .foregroundStyle(LoveSongTheme.textTertiary)
        }
        .padding(.vertical, 2)
    }
}

struct EmptyLibraryView: View {
    var onFiles: () -> Void
    var onWifi: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            VStack(spacing: 10) {
                Text(L10n.emptyLibraryTitle)
                    .font(LoveSongTheme.Font.emptyTitle)
                    .foregroundStyle(LoveSongTheme.textPrimary)
                Text(L10n.emptyLibrarySubtitle)
                    .font(.subheadline)
                    .foregroundStyle(LoveSongTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
            Button(action: onFiles) {
                Text(L10n.emptyLibraryAction)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LoveSongTheme.stageBackground)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(LoveSongTheme.spotlight, in: Capsule())
            }
            .padding(.top, 4)
            QuietImportBar(onFiles: onFiles, onWifi: onWifi)
                .padding(.horizontal, LoveSongTheme.Space.screen)
                .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
