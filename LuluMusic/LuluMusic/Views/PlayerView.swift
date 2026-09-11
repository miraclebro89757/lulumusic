import SwiftData
import SwiftUI
import UIKit

struct PlayerView: View {
    @Environment(PlayerEngine.self) private var player
    @Environment(DanmakuService.self) private var danmakuService
    @Environment(AppNavigation.self) private var navigation
    @Environment(LibraryService.self) private var library
    @Query(sort: \Track.dateAdded, order: .reverse) private var tracks: [Track]

    @State private var runtime = DanmakuRuntime(store: InMemoryDanmakuStore())
    @State private var draft = ""
    @State private var inspected: FlyingDanmaku?
    @FocusState private var danmakuFocused: Bool
    @State private var showPhrases = false
    @State private var venueDraft = ""
    @State private var editingVenue = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let artworkSide = min(LoveSongTheme.Space.coverMax, min(proxy.size.width - 24, proxy.size.height * 0.42))
            ZStack {
                LoveSongTheme.stageBackground.ignoresSafeArea()
                ConcertStageBackground(
                    url: player.current?.artworkURL,
                    seed: (player.current?.title ?? "") + (player.current?.artist ?? "empty")
                )
                .contentShape(Rectangle())
                .onTapGesture { danmakuFocused = false }

                if player.current == nil {
                    EmptyStateView(
                        systemImage: "opticaldisc",
                        title: L10n.noTrack,
                        primaryTitle: L10n.pickFromLibrary,
                        primaryAction: { navigation.tab = .playlist }
                    )
                } else {
                    VStack(spacing: 0) {
                        header
                            .padding(.horizontal, LoveSongTheme.Space.screen)
                            .padding(.top, 4)

                        Spacer(minLength: 12)

                        coverStack(side: artworkSide)
                            .padding(.horizontal, 12)

                        Spacer(minLength: 16)

                        metadata
                            .padding(.horizontal, LoveSongTheme.Space.screen)

                        VenueGlassStrip(
                            text: player.current?.venueTag ?? "",
                            onOpenLive: { navigation.tab = .live },
                            onEdit: { beginVenueEdit() }
                        )
                        .padding(.horizontal, LoveSongTheme.Space.screen)
                        .padding(.top, 12)

                        Spacer(minLength: 20)

                        ProgressSeekBar(
                            current: player.currentTime,
                            duration: player.duration,
                            enabled: player.current != nil
                        ) { player.seek(to: $0) }
                        .padding(.horizontal, 24)
                        .padding(.top, 4)

                        PlayerTransport(
                            isPlaying: player.isPlaying,
                            enabled: player.current != nil,
                            playbackMode: player.playbackMode,
                            modeTitle: player.playbackModeTitle,
                            onMode: { player.cyclePlaybackMode() },
                            onPrevious: { player.playPrevious() },
                            onPlayPause: { player.togglePlayPause() },
                            onNext: { player.playNext() }
                        )
                        .padding(.horizontal, LoveSongTheme.Space.screen)
                        .padding(.top, 16)

                        Spacer(minLength: 4)
                    }
                    .padding(.bottom, 8)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 10) {
            if player.current != nil {
                GlassDanmakuComposer(
                    text: $draft,
                    enabled: true,
                    focused: $danmakuFocused,
                    onSend: sendDanmaku,
                    onSmile: { showPhrases = true }
                )
                .padding(.horizontal, LoveSongTheme.Space.screen)
                .padding(.bottom, 6)
            }
        }
        .foregroundStyle(LoveSongTheme.textPrimary)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showPhrases) {
            DanmakuModal(
                enabled: player.current != nil,
                onPick: { phrase in
                    showPhrases = false
                    sendPhrase(phrase)
                }
            )
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

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                player.danmakuEnabled.toggle()
            } label: {
                Image(systemName: player.danmakuEnabled ? "captions.bubble.fill" : "captions.bubble")
                    .font(.body.weight(.medium))
                    .frame(width: 44, height: 44)
                    .foregroundStyle(player.danmakuEnabled ? LoveSongTheme.accent : LoveSongTheme.textTertiary)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(LoveSongTheme.hairline, lineWidth: 1))
            }
            .accessibilityLabel(player.danmakuEnabled ? L10n.danmakuOn : L10n.danmakuOff)
            Spacer(minLength: 8)
            Button {
                navigation.tab = .playlist
            } label: {
                Image(systemName: "list.bullet")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(LoveSongTheme.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(LoveSongTheme.hairline, lineWidth: 1))
            }
            .accessibilityLabel(L10n.tabPlaylist)
        }
        .frame(minHeight: 44)
    }

    private func coverStack(side: CGFloat) -> some View {
        ArtworkView(
            url: player.current?.artworkURL,
            seed: (player.current?.title ?? L10n.noTrack) + (player.current?.artist ?? ""),
            cornerRadius: PlayerChrome.coverRadius
        )
        .frame(width: side, height: side)
        .overlay {
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
        }
        .shadow(color: LoveSongTheme.coverShadow, radius: 24, y: 12)
        .contentShape(RoundedRectangle(cornerRadius: PlayerChrome.coverRadius, style: .continuous))
        .onTapGesture { navigation.tab = .live }
        .frame(maxWidth: .infinity)
    }

    private var metadata: some View {
        VStack(spacing: 6) {
            Text(player.current?.title ?? L10n.noTrack)
                .font(LoveSongTheme.Font.playerTitle)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .foregroundStyle(LoveSongTheme.textPrimary)
            Text(player.current?.artist ?? L10n.pickFromLibrary)
                .font(LoveSongTheme.Font.playerArtist)
                .foregroundStyle(LoveSongTheme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func sendPhrase(_ text: String) {
        draft = text
        sendDanmaku()
    }

    private func sendDanmaku() {
        guard let id = player.current?.id else { return }
        runtime.store = danmakuService
        runtime.enabled = player.danmakuEnabled
        let text = draft
        draft = ""
        let ms = player.livePlayerMilliseconds()
        if let record = runtime.send(trackId: id, text: text, currentTimeMS: ms) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            Task { danmakuService.persist(record) }
        } else {
            draft = text
        }
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
                    let laneBand = size.height * 0.58
                    let laneStart = size.height * 0.22
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
