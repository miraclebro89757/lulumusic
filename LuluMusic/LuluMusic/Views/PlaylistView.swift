import SwiftData
import SwiftUI

struct PlaylistView: View {
    @Environment(PlayerEngine.self) private var player
    @Environment(LibraryService.self) private var library
    @Environment(AppNavigation.self) private var navigation
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
                        .padding(.bottom, 12)

                    if library.isImporting {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(LoveSongTheme.accent)
                            Text(L10n.importingBanner)
                                .font(.caption)
                                .foregroundStyle(LoveSongTheme.textSecondary)
                            Spacer()
                        }
                        .padding(.horizontal, LoveSongTheme.Space.screen)
                        .padding(.bottom, 8)
                    }

                    if tracks.isEmpty {
                        EmptyStateView(
                            systemImage: "opticaldisc",
                            title: L10n.emptyLibraryTitle,
                            subtitle: L10n.emptyLibrarySubtitle,
                            primaryTitle: L10n.emptyLibraryAction,
                            primaryAction: { showFiles = true },
                            secondaryTitle: L10n.emptyWifiAction,
                            secondaryAction: { showWifi = true }
                        )
                    } else if filtered.isEmpty {
                        Text(L10n.searchNoResults)
                            .font(.caption)
                            .foregroundStyle(LoveSongTheme.textSecondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            .padding(.top, 32)
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
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: LoveSongTheme.Space.screen, bottom: 4, trailing: LoveSongTheme.Space.screen))
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
                        .background(LoveSongTheme.stageBackground)
                    }
                }
            }
            .navigationTitle(L10n.playlistTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(LoveSongTheme.stageBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button { showFiles = true } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(LoveSongTheme.accent)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel(L10n.importFilesButton)
                        Button { showWifi = true } label: {
                            Image(systemName: "wifi")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(LoveSongTheme.accent)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel(L10n.wifiImportShort)
                    }
                }
            }
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
        navigation.tab = .player
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

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if isCurrent {
                        Image(systemName: isPlaying ? "waveform" : "pause.fill")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(LoveSongTheme.accent)
                    }
                    Text(track.title)
                        .font(LoveSongTheme.Font.rowTitle)
                        .foregroundStyle(LoveSongTheme.textPrimary)
                        .lineLimit(1)
                }
                Text(track.artist)
                    .font(LoveSongTheme.Font.rowCaption)
                    .foregroundStyle(LoveSongTheme.textSecondary)
                    .lineLimit(1)
                if !track.venueTag.isEmpty {
                    VenueChip(text: track.venueTag, compact: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(TimeFormat.duration(track.duration))
                .font(LoveSongTheme.Font.time)
                .foregroundStyle(LoveSongTheme.textTertiary)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 72)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isCurrent ? LoveSongTheme.stageElevated : LoveSongTheme.glassFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(LoveSongTheme.hairline, lineWidth: 1)
        )
    }
}
