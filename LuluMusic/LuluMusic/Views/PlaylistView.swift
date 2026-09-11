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
    @State private var showAddMenu = false
    @State private var venueDraft = ""
    @State private var venueTrack: Track?
    @State private var menuTrack: Track?

    var filtered: [Track] {
        let infos = tracks.map(\.asSearchInfo)
        let ids = Set(LibrarySearch.filtered(infos, query: search).map(\.id))
        return tracks.filter { ids.contains($0.id) }
    }

    var body: some View {
        ZStack {
            LoveSongTheme.stageFill
            VStack(spacing: 0) {
                playlistCard
                    .padding(.top, 56)
                Spacer(minLength: 16)
                Button {
                    navigation.tab = .player
                } label: {
                    Text(L10n.playlistReturn)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(LoveSongTheme.textPrimary.opacity(0.92))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white.opacity(0.06), in: Capsule())
                        .overlay(Capsule().stroke(LoveSongTheme.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 28)
                .padding(.bottom, 16)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task { await library.importSharedDocumentsIfNeeded() }
        .sheet(isPresented: $showWifi) {
            NavigationStack {
                WebUploadView()
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
        .confirmationDialog(L10n.emptyLibraryAction, isPresented: $showAddMenu, titleVisibility: .visible) {
            Button(L10n.importFilesButton) { showFiles = true }
            Button(L10n.wifiImportShort) { showWifi = true }
            Button(L10n.cancel, role: .cancel) {}
        }
        .confirmationDialog(menuTrack?.title ?? "", isPresented: Binding(
            get: { menuTrack != nil },
            set: { if !$0 { menuTrack = nil } }
        ), titleVisibility: .visible) {
            Button(L10n.playNow) {
                if let track = menuTrack { play(track) }
                menuTrack = nil
            }
            Button(L10n.setVenue) {
                if let track = menuTrack {
                    venueTrack = track
                    venueDraft = track.venueTag
                }
                menuTrack = nil
            }
            Button(L10n.wifiImportShort) {
                menuTrack = nil
                showWifi = true
            }
            Button(L10n.delete, role: .destructive) {
                if let track = menuTrack {
                    try? library.delete(track, player: player)
                }
                menuTrack = nil
            }
            Button(L10n.cancel, role: .cancel) { menuTrack = nil }
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

    private var playlistCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.playlistTitle)
                        .font(LoveSongTheme.Font.wordmark)
                        .foregroundStyle(LoveSongTheme.textPrimary)
                    Text(String(format: L10n.playlistConcertCountFormat, tracks.count))
                        .font(.subheadline)
                        .foregroundStyle(LoveSongTheme.textSecondary)
                }
                Spacer()
                Button { showAddMenu = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(LoveSongTheme.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.08), in: Circle())
                        .overlay(Circle().stroke(LoveSongTheme.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.importFilesButton)
            }

            if library.isImporting {
                HStack(spacing: 8) {
                    ProgressView().tint(LoveSongTheme.accent)
                    Text(L10n.importingBanner)
                        .font(.caption)
                        .foregroundStyle(LoveSongTheme.textSecondary)
                }
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
                .frame(minHeight: 220)
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(filtered) { track in
                            PlaylistTrackRow(
                                track: track,
                                isCurrent: player.current?.id == track.id,
                                isPlaying: player.isPlaying,
                                onPlay: { play(track) },
                                onMore: { menuTrack = track }
                            )
                        }
                    }
                }
                .frame(maxHeight: 420)
            }
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: LoveSongTheme.Space.modalRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: LoveSongTheme.Space.modalRadius, style: .continuous)
                        .fill(LoveSongTheme.stageElevated.opacity(0.72))
                }
        }
        .overlay(
            RoundedRectangle(cornerRadius: LoveSongTheme.Space.modalRadius, style: .continuous)
                .stroke(LoveSongTheme.hairline, lineWidth: 1)
        )
        .padding(.horizontal, 20)
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

struct PlaylistTrackRow: View {
    let track: Track
    var isCurrent: Bool
    var isPlaying: Bool
    var onPlay: () -> Void
    var onMore: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                ArtworkView(
                    url: track.resolvedArtworkURL,
                    seed: track.title + track.artist,
                    cornerRadius: 12
                )
                .frame(width: 48, height: 48)
                if isCurrent {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LoveSongTheme.accent.opacity(0.38))
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white)
                }
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(track.title)
                        .font(LoveSongTheme.Font.rowTitle)
                        .foregroundStyle(LoveSongTheme.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: 6)
                    Text(TimeFormat.duration(track.duration))
                        .font(LoveSongTheme.Font.time)
                        .foregroundStyle(LoveSongTheme.textSecondary)
                }
                Text(track.artist)
                    .font(LoveSongTheme.Font.rowCaption)
                    .foregroundStyle(LoveSongTheme.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onMore) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LoveSongTheme.textSecondary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("更多")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isCurrent ? LoveSongTheme.accent.opacity(0.22) : Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isCurrent ? LoveSongTheme.accent.opacity(0.85) : LoveSongTheme.hairline, lineWidth: isCurrent ? 1.2 : 1)
                .shadow(color: isCurrent ? LoveSongTheme.accentGlow.opacity(0.35) : .clear, radius: 8, y: 0)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture(perform: onPlay)
    }
}

struct TrackRow: View {
    let track: Track
    var isCurrent: Bool
    var isPlaying: Bool

    var body: some View {
        PlaylistTrackRow(
            track: track,
            isCurrent: isCurrent,
            isPlaying: isPlaying,
            onPlay: {},
            onMore: {}
        )
    }
}
