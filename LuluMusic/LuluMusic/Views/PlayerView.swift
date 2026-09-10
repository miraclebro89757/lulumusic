import SwiftUI

struct PlayerView: View {
    @Environment(PlayerEngine.self) private var player
    @Environment(DanmakuService.self) private var danmakuService
    var showsDismiss = false

    @State private var runtime = DanmakuRuntime(store: InMemoryDanmakuStore())
    @State private var draft = ""
    @State private var inspected: FlyingDanmaku?
    @FocusState private var danmakuFocused: Bool

    var body: some View {
        GeometryReader { proxy in
            let artworkSide = min(proxy.size.width - 48, proxy.size.height * 0.42)
            ZStack {
                ConcertStageBackground(
                    url: player.current?.artworkURL,
                    seed: (player.current?.title ?? "") + (player.current?.artist ?? "empty")
                )

                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, LoveSongTheme.Space.screen)
                        .padding(.top, 6)

                    Spacer(minLength: 12)

                    coverStack(side: artworkSide)
                        .padding(.horizontal, LoveSongTheme.Space.screen)

                    Spacer(minLength: 18)

                    metadata
                        .padding(.horizontal, LoveSongTheme.Space.screen)

                    ConcertScrubber(
                        current: player.currentTime,
                        duration: player.duration,
                        enabled: player.current != nil
                    ) { player.seek(to: $0) }
                    .padding(.horizontal, LoveSongTheme.Space.screen)
                    .padding(.top, 18)

                    transport
                        .padding(.top, 18)

                    Spacer(minLength: 8)
                }
                .padding(.bottom, 8)
            }
        }
        .ignoresSafeArea(.keyboard)
        .safeAreaInset(edge: .bottom, spacing: 10) {
            GlassDanmakuComposer(
                text: $draft,
                enabled: player.current != nil,
                focused: $danmakuFocused,
                onSend: sendDanmaku
            )
            .padding(.horizontal, LoveSongTheme.Space.screen)
            .padding(.bottom, 6)
        }
        .foregroundStyle(LoveSongTheme.textPrimary)
        .toolbar(.hidden, for: .navigationBar)
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
        .onAppear { reloadDanmakuCatalog() }
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
            if showsDismiss {
                GlassCircleButton(systemName: "chevron.down") {
                    player.isFullPlayerPresented = false
                }
            }
            if let tag = player.current?.venueTag, !tag.isEmpty {
                VenueChip(text: tag)
            }
            Spacer(minLength: 8)
            Button {
                player.danmakuEnabled.toggle()
            } label: {
                Image(systemName: player.danmakuEnabled ? "captions.bubble.fill" : "captions.bubble")
                    .font(.body.weight(.medium))
                    .foregroundStyle(player.danmakuEnabled ? LoveSongTheme.spotlight : LoveSongTheme.textTertiary)
            }
            .accessibilityLabel(player.danmakuEnabled ? L10n.danmakuOn : L10n.danmakuOff)
        }
        .frame(minHeight: 36)
    }

    private func coverStack(side: CGFloat) -> some View {
        ArtworkView(
            url: player.current?.artworkURL,
            seed: (player.current?.title ?? L10n.noTrack) + (player.current?.artist ?? ""),
            cornerRadius: 18
        )
        .frame(width: side, height: side)
        .overlay {
            if player.danmakuEnabled {
                DanmakuOverlay(items: runtime.flying, size: CGSize(width: side, height: side)) { item in
                    inspected = item
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .shadow(color: LoveSongTheme.coverShadow, radius: 28, y: 16)
        .scaleEffect(player.isPlaying ? 1.015 : 1.0)
        .animation(.spring(response: 0.72, dampingFraction: 0.86), value: player.isPlaying)
        .frame(maxWidth: .infinity)
    }

    private var metadata: some View {
        VStack(spacing: 6) {
            Text(player.current?.title ?? L10n.noTrack)
                .font(LoveSongTheme.Font.playerTitle)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundStyle(LoveSongTheme.textPrimary)
            Text(player.current?.artist ?? L10n.pickFromLibrary)
                .font(LoveSongTheme.Font.playerArtist)
                .foregroundStyle(LoveSongTheme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var transport: some View {
        HStack(spacing: 0) {
            Button { player.cyclePlaybackMode() } label: {
                Image(systemName: player.playbackMode.systemImage)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(player.playbackMode == .sequential ? LoveSongTheme.textTertiary : LoveSongTheme.spotlight)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(player.playbackModeTitle)

            Spacer()

            Button { player.playPrevious() } label: {
                Image(systemName: "backward.fill")
                    .font(.title2)
                    .foregroundStyle(LoveSongTheme.textPrimary)
                    .frame(width: 48, height: 48)
            }

            SpotlightPlayButton(
                isPlaying: player.isPlaying,
                enabled: player.current != nil,
                action: { player.togglePlayPause() }
            )
            .padding(.horizontal, 22)

            Button { player.playNext() } label: {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundStyle(LoveSongTheme.textPrimary)
                    .frame(width: 48, height: 48)
            }

            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 12)
        .disabled(player.queue.isEmpty)
    }

    private func sendDanmaku() {
        guard let id = player.current?.id else { return }
        runtime.store = danmakuService
        runtime.enabled = player.danmakuEnabled
        if runtime.send(trackId: id, text: draft, currentTimeMS: player.currentTimeMS) != nil {
            draft = ""
            danmakuFocused = false
        }
    }

    private func reloadDanmakuCatalog() {
        runtime.store = danmakuService
        runtime.enabled = player.danmakuEnabled
        runtime.resetTrack()
        guard let id = player.current?.id else { return }
        runtime.tick(trackId: id, currentTimeMS: player.currentTimeMS)
    }
}

struct DanmakuOverlay: View {
    var items: [FlyingDanmaku]
    var size: CGSize
    var onLongPress: (FlyingDanmaku) -> Void

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: items.isEmpty)) { timeline in
            ZStack(alignment: .topLeading) {
                ForEach(items) { item in
                    let travel = min(1, max(0, timeline.date.timeIntervalSince(item.spawnedAt) / 6.2))
                    let x = size.width - travel * (size.width + 180)
                    let laneBand = size.height * 0.62
                    let laneStart = size.height * 0.20
                    let y = laneStart + CGFloat(item.lane) * (laneBand / 3.0)
                    let fade: Double = {
                        if item.fading { return 0.18 }
                        if travel < 0.08 { return travel / 0.08 }
                        if travel > 0.86 { return max(0, (1 - travel) / 0.14) }
                        return 1
                    }()
                    Text(item.record.text)
                        .font(.system(size: item.record.fontSize, weight: .medium, design: .rounded))
                        .foregroundStyle(item.lane == 1 ? LoveSongTheme.danmakuAccent : LoveSongTheme.danmaku)
                        .shadow(color: .black.opacity(0.85), radius: 3, y: 1)
                        .offset(x: x, y: y)
                        .opacity(fade)
                        .onLongPressGesture { onLongPress(item) }
                }
            }
        }
        .allowsHitTesting(true)
    }
}

struct FullPlayerSheet: View {
    var body: some View {
        PlayerView(showsDismiss: true)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(LoveSongTheme.stageBackground)
    }
}
