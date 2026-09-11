import SwiftData
import SwiftUI
import UIKit

struct PlayerView: View {
    @Environment(PlayerEngine.self) private var player
    @Environment(DanmakuService.self) private var danmakuService
    @Environment(AppNavigation.self) private var navigation
    @Environment(LibraryService.self) private var library
    @Environment(FavoriteStore.self) private var favorites
    @Query(sort: \Track.dateAdded, order: .reverse) private var tracks: [Track]

    @State private var runtime = DanmakuRuntime(store: InMemoryDanmakuStore())
    @State private var inspected: FlyingDanmaku?
    @State private var venueDraft = ""
    @State private var editingVenue = false
    @State private var showMore = false
    @State private var showWifi = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let artworkSide = min(LoveSongTheme.Space.coverMax, proxy.size.width * 0.76)
            ZStack {
                LoveSongTheme.stageBackground.ignoresSafeArea()
                RadialGradient(
                    colors: [LoveSongTheme.accent.opacity(0.16), Color.clear],
                    center: .top,
                    startRadius: 20,
                    endRadius: 420
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 4)

                    Spacer(minLength: 14)

                    stackedCover(side: artworkSide)
                        .padding(.horizontal, 16)

                    Spacer(minLength: 18)

                    ProgressSeekBar(
                        current: player.currentTime,
                        duration: player.duration,
                        enabled: player.current != nil
                    ) { player.seek(to: $0) }
                    .padding(.horizontal, 26)

                    PlayerTransport(
                        isPlaying: player.isPlaying,
                        enabled: player.current != nil,
                        liked: currentLiked,
                        onLike: toggleLike,
                        onPrevious: { player.playPrevious() },
                        onPlayPause: { player.togglePlayPause() },
                        onNext: { player.playNext() },
                        onMore: { showMore = true }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    VenueGlassStrip(
                        text: player.current?.venueTag ?? "",
                        dateText: concertDateFull,
                        onOpenLive: { navigation.tab = .live },
                        onEdit: { beginVenueEdit() }
                    )
                    .padding(.horizontal, 18)
                    .padding(.top, 18)

                    Spacer(minLength: 8)
                }
                .padding(.bottom, 8)
            }
        }
        .foregroundStyle(LoveSongTheme.textPrimary)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showWifi) {
            NavigationStack { WebUploadView() }
        }
        .confirmationDialog("更多", isPresented: $showMore, titleVisibility: .hidden) {
            Button(L10n.tabPlaylist) { navigation.tab = .playlist }
            Button(player.playbackModeTitle) { player.cyclePlaybackMode() }
            Button(player.danmakuEnabled ? L10n.danmakuOff : L10n.danmakuOn) {
                player.danmakuEnabled.toggle()
            }
            Button(L10n.wifiImportShort) { showWifi = true }
            Button(L10n.cancel, role: .cancel) {}
        }
        .alert(L10n.setVenue, isPresented: $editingVenue) {
            TextField(L10n.venuePlaceholder, text: $venueDraft)
            Button(L10n.done) { commitVenueEdit() }
            Button(L10n.cancel, role: .cancel) { editingVenue = false }
        }
        .onAppear { reloadDanmakuCatalog() }
        .onChange(of: navigation.tab) { _, tab in
            if tab == .player { reloadDanmakuCatalog() }
        }
        .onChange(of: player.current?.id) { _, _ in
            reloadDanmakuCatalog()
        }
        .onChange(of: player.currentTimeMS) { _, now in
            guard player.danmakuEnabled, let id = player.current?.id else { return }
            runtime.tick(trackId: id, currentTimeMS: now)
        }
        .onChange(of: player.danmakuEnabled) { _, enabled in
            runtime.enabled = enabled
            player.persistResume()
            if enabled { reloadDanmakuCatalog() } else { runtime.flying = [] }
        }
        .alert(
            inspected?.record.text ?? "",
            isPresented: Binding(
                get: { inspected != nil },
                set: { if !$0 { inspected = nil } }
            )
        ) {
            Button(L10n.done, role: .cancel) { inspected = nil }
        } message: {
            if let item = inspected {
                Text("\(RelativeDateFormat.string(from: item.record.createdAt))\n\(TimeFormat.duration(TimeInterval(item.record.timestampMS) / 1000))")
            }
        }
    }

    private var currentLiked: Bool {
        guard let id = player.current?.id else { return false }
        return favorites.isLiked(id)
    }

    private var concertDate: Date {
        player.current?.addedAt ?? Date()
    }

    private var concertDateFull: String {
        ConcertDateFormat.full(concertDate)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(LoveSongTheme.accent)
                        .frame(width: 8, height: 8)
                    Text(L10n.liveMemory)
                        .font(LoveSongTheme.Font.headerTitle)
                        .foregroundStyle(LoveSongTheme.textPrimary)
                }
                Text("\(L10n.concertLabel) · \(concertDateFull)")
                    .font(LoveSongTheme.Font.headerSub)
                    .foregroundStyle(LoveSongTheme.textSecondary)
                    .padding(.leading, 16)
            }
            Spacer(minLength: 8)
            Button { showMore = true } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(LoveSongTheme.textPrimary)
                    .rotationEffect(.degrees(90))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("更多")
        }
        .frame(minHeight: 44)
    }

    private func stackedCover(side: CGFloat) -> some View {
        ZStack {
            ArtworkView(
                url: player.current?.artworkURL,
                seed: (player.current?.title ?? "rear") + "rear",
                cornerRadius: PlayerChrome.coverRadius,
                placeholderAsset: ReferenceArt.liveStage
            )
            .frame(width: side + 4, height: side + 4)
            .overlay {
                RoundedRectangle(cornerRadius: PlayerChrome.coverRadius, style: .continuous)
                    .fill(Color(hex: 0x2E1065).opacity(0.62))
            }
            .offset(x: 16, y: -10)
            .allowsHitTesting(false)

            ZStack(alignment: .bottomLeading) {
                ArtworkView(
                    url: player.current?.artworkURL,
                    seed: (player.current?.title ?? L10n.noTrack) + (player.current?.artist ?? ""),
                    cornerRadius: PlayerChrome.coverRadius,
                    placeholderAsset: ReferenceArt.liveStage
                )
                .frame(width: side, height: side)

                LinearGradient(
                    colors: [Color.black.opacity(0.72), Color.black.opacity(0.08), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .clipShape(RoundedRectangle(cornerRadius: PlayerChrome.coverRadius, style: .continuous))
                .allowsHitTesting(false)

                if player.danmakuEnabled {
                    DanmakuOverlay(
                        items: runtime.flying,
                        size: CGSize(width: side, height: side),
                        reduceMotion: reduceMotion
                    ) { item in
                        inspected = item
                    }
                    .clipShape(RoundedRectangle(cornerRadius: PlayerChrome.coverRadius, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 6) {
                    MiniEQBars(isPlaying: player.isPlaying)
                    Text(player.current?.title ?? L10n.noTrack)
                        .font(LoveSongTheme.Font.playerTitle)
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                    Text(player.current?.artist ?? L10n.pickFromLibrary)
                        .font(LoveSongTheme.Font.playerArtist)
                        .foregroundStyle(Color.white.opacity(0.72))
                        .lineLimit(1)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .allowsHitTesting(false)
            }
            .overlay(alignment: .topTrailing) {
                LiveStatusPill()
                    .padding(12)
            }
            .shadow(color: LoveSongTheme.coverShadow, radius: 24, y: 12)
            .contentShape(RoundedRectangle(cornerRadius: PlayerChrome.coverRadius, style: .continuous))
            .onTapGesture { navigation.tab = .live }
        }
        .frame(width: side + 16, height: side + 10)
        .frame(maxWidth: .infinity)
    }

    private func toggleLike() {
        guard let id = player.current?.id else { return }
        favorites.toggle(id)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func reloadDanmakuCatalog() {
        runtime.store = danmakuService
        runtime.enabled = player.danmakuEnabled
        runtime.resetTrack()
        guard let id = player.current?.id else { return }
        runtime.tick(trackId: id, currentTimeMS: player.currentTimeMS)
    }

    private func beginVenueEdit() {
        venueDraft = player.current?.venueTag ?? ""
        editingVenue = true
    }

    private func commitVenueEdit() {
        editingVenue = false
        guard let id = player.current?.id,
              let track = tracks.first(where: { $0.id == id }) else { return }
        library.updateVenueTag(track, venueTag: venueDraft)
    }
}

struct LiveStatusPill: View {
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(LoveSongTheme.accent)
                .frame(width: 5, height: 5)
            Text(L10n.liveStatusPill)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.92))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.42), in: Capsule())
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.16), lineWidth: 1))
    }
}

struct MiniEQBars: View {
    var isPlaying: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.12, paused: !isPlaying)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<5, id: \.self) { index in
                    let wave = isPlaying
                        ? 0.35 + 0.65 * abs(sin(t * (2.4 + Double(index) * 0.55) + Double(index)))
                        : 0.28
                    Capsule()
                        .fill(LoveSongTheme.accent)
                        .frame(width: 3, height: 14 * wave)
                }
            }
            .frame(height: 14, alignment: .bottom)
        }
    }
}

struct DanmakuOverlay: View {
    var items: [FlyingDanmaku]
    var size: CGSize
    var reduceMotion: Bool = false
    var onLongPress: (FlyingDanmaku) -> Void

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: items.isEmpty)) { timeline in
            ZStack(alignment: .topLeading) {
                Color.clear.allowsHitTesting(false)
                ForEach(items) { item in
                    let travel = min(1, max(0, timeline.date.timeIntervalSince(item.spawnedAt) / (reduceMotion ? 1.2 : 3.5)))
                    let x = reduceMotion ? size.width * 0.18 : size.width - travel * (size.width + 180)
                    let laneBand = size.height * 0.42
                    let laneStart = size.height * 0.16
                    let y = laneStart + CGFloat(item.lane) * (laneBand / 3.0)
                    let fade: Double = {
                        if item.fading { return 0.18 }
                        if reduceMotion {
                            if travel < 0.15 { return travel / 0.15 }
                            if travel > 0.75 { return max(0, (1 - travel) / 0.25) }
                            return 1
                        }
                        if travel < 0.08 { return travel / 0.08 }
                        if travel > 0.86 { return max(0, (1 - travel) / 0.14) }
                        return 1
                    }()
                    Text(item.record.text)
                        .font(.system(size: min(17, max(15, item.record.fontSize)), weight: .medium))
                        .foregroundStyle(LoveSongTheme.danmaku)
                        .shadow(color: LoveSongTheme.danmakuFlyStroke, radius: 0.5)
                        .shadow(color: .black.opacity(0.86), radius: 3, y: 1)
                        .offset(x: x, y: y)
                        .opacity(fade)
                        .accessibilityHidden(true)
                        .onLongPressGesture { onLongPress(item) }
                }
            }
        }
        .allowsHitTesting(true)
    }
}
