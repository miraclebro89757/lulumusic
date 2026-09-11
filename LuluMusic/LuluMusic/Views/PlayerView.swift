import SwiftUI

struct PlayerView: View {
    @Environment(PlayerEngine.self) private var player
    @Environment(DanmakuService.self) private var danmakuService
    @Environment(\.selectedAppTab) private var selectedTab
    var showsDismiss = false

    @State private var runtime = DanmakuRuntime(store: InMemoryDanmakuStore())
    @State private var draft = ""
    @State private var inspected: FlyingDanmaku?
    @FocusState private var danmakuFocused: Bool
    @State private var chromeReady = false
    @State private var waveformPeaks: [Float] = []

    var body: some View {
        GeometryReader { proxy in
            let artworkSide = min(proxy.size.width - 24, proxy.size.height * 0.54)
            ZStack {
                ConcertStageBackground(
                    url: player.current?.artworkURL,
                    seed: (player.current?.title ?? "") + (player.current?.artist ?? "empty")
                )
                .contentShape(Rectangle())
                .onTapGesture { danmakuFocused = false }

                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, LoveSongTheme.Space.screen)
                        .padding(.top, 4)
                        .opacity(chromeOpacity)

                    Spacer(minLength: 8)

                    coverStack(side: artworkSide)
                        .padding(.horizontal, 12)

                    Spacer(minLength: 14)

                    metadata
                        .padding(.horizontal, LoveSongTheme.Space.screen)
                        .opacity(chromeOpacity)

                    ConcertScrubber(
                        current: player.currentTime,
                        duration: player.duration,
                        peaks: waveformPeaks,
                        enabled: player.current != nil,
                        accent: CoverPalette.waveformTint(from: player.current?.artworkURL)
                    ) { player.seek(to: $0) }
                    .padding(.horizontal, LoveSongTheme.Space.screen)
                    .padding(.top, 14)
                    .opacity(chromeOpacity)

                    PlayerTransport(
                        isPlaying: player.isPlaying,
                        enabled: player.current != nil,
                        playbackMode: player.playbackMode,
                        modeTitle: player.playbackModeTitle,
                        onMode: { player.cyclePlaybackMode() },
                        onPrevious: { player.playPrevious() },
                        onPlayPause: { player.togglePlayPause() },
                        onNext: { player.playNext() },
                        playIsSource: coverIsSource,
                        playMatchActive: coverMatchActive
                    )
                    .padding(.horizontal, LoveSongTheme.Space.screen)
                    .padding(.top, 12)
                    .opacity(chromeOpacity)

                    Spacer(minLength: 4)
                }
                .padding(.bottom, 8)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 10) {
            GlassDanmakuComposer(
                text: $draft,
                enabled: player.current != nil,
                focused: $danmakuFocused,
                onSend: sendDanmaku
            )
            .padding(.horizontal, LoveSongTheme.Space.screen)
            .padding(.bottom, 6)
            .opacity(chromeOpacity)
        }
        .foregroundStyle(LoveSongTheme.textPrimary)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            reloadDanmakuCatalog()
            loadWaveform()
            if showsDismiss {
                withAnimation(.easeOut(duration: 0.28).delay(0.05)) { chromeReady = true }
            } else {
                chromeReady = true
            }
        }
        .onChange(of: player.current?.id) { _, _ in
            reloadDanmakuCatalog()
            loadWaveform()
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

    private var chromeOpacity: Double {
        showsDismiss ? (chromeReady ? 1 : 0) : 1
    }

    private var matchSurface: NowPlayingMatchSurface {
        showsDismiss ? .fullPlayer : .playerTab
    }

    private var coverIsSource: Bool {
        NowPlayingMatchedGeometry.isSource(
            matchSurface,
            selectedTab: selectedTab,
            isFullPlayerPresented: player.isFullPlayerPresented
        )
    }

    private var coverMatchActive: Bool {
        NowPlayingMatchedGeometry.participates(
            matchSurface,
            selectedTab: selectedTab,
            isFullPlayerPresented: player.isFullPlayerPresented
        )
    }

    private var header: some View {
        HStack(spacing: 12) {
            if showsDismiss {
                GlassCircleButton(systemName: "chevron.down") {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
                        player.isFullPlayerPresented = false
                    }
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
                    .frame(width: 36, height: 36)
                    .foregroundStyle(player.danmakuEnabled ? LoveSongTheme.spotlight : LoveSongTheme.textTertiary)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(LoveSongTheme.hairline, lineWidth: 1))
            }
            .accessibilityLabel(player.danmakuEnabled ? L10n.danmakuOn : L10n.danmakuOff)
        }
        .frame(minHeight: 36)
    }

    private func coverStack(side: CGFloat) -> some View {
        ArtworkView(
            url: player.current?.artworkURL,
            seed: (player.current?.title ?? L10n.noTrack) + (player.current?.artist ?? ""),
            cornerRadius: PlayerChrome.coverRadius
        )
        .frame(width: side, height: side)
        .modifier(NowPlayingCoverMatch(isSource: coverIsSource, isActive: coverMatchActive))
        .overlay {
            if player.danmakuEnabled {
                DanmakuOverlay(items: runtime.flying, size: CGSize(width: side, height: side)) { item in
                    inspected = item
                }
                .clipShape(RoundedRectangle(cornerRadius: PlayerChrome.coverRadius, style: .continuous))
            }
        }
        .shadow(color: LoveSongTheme.coverShadow, radius: 28, y: 16)
        .scaleEffect(player.isPlaying ? 1.015 : 1.0)
        .animation(.spring(response: 0.72, dampingFraction: 0.86), value: player.isPlaying)
        .frame(maxWidth: .infinity)
    }

    private var metadata: some View {
        VStack(spacing: 8) {
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

    private func sendDanmaku() {
        guard let id = player.current?.id else { return }
        runtime.store = danmakuService
        runtime.enabled = player.danmakuEnabled
        let text = draft
        draft = ""
        let ms = player.livePlayerMilliseconds()
        if let record = runtime.send(trackId: id, text: text, currentTimeMS: ms) {
            Task { danmakuService.persist(record) }
        } else {
            draft = text
        }
    }

    private func loadWaveform() {
        guard let url = player.current?.fileURL else {
            waveformPeaks = []
            return
        }
        let trackID = player.current?.id
        Task {
            let peaks = await AudioWaveformAnalyzer.peaks(from: url)
            await MainActor.run {
                guard player.current?.id == trackID else { return }
                waveformPeaks = peaks
            }
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
                LinearGradient(
                    colors: [Color.black.opacity(0.18), .clear, .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                ForEach(items) { item in
                    let travel = min(1, max(0, timeline.date.timeIntervalSince(item.spawnedAt) / 6.2))
                    let x = size.width - travel * (size.width + 180)
                    let laneBand = size.height * 0.58
                    let laneStart = size.height * 0.22
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
                        .shadow(color: .black.opacity(0.86), radius: 3, y: 1)
                        .offset(x: x, y: y)
                        .opacity(fade)
                        .onLongPressGesture { onLongPress(item) }
                }
            }
        }
        .allowsHitTesting(true)
    }
}

struct FullPlayerOverlay: View {
    var body: some View {
        PlayerView(showsDismiss: true)
    }
}
