import SwiftUI

struct PlayerView: View {
    @Environment(PlayerEngine.self) private var player
    @Environment(DanmakuService.self) private var danmakuService
    var showsDismiss = false

    @State private var isScrubbing = false
    @State private var scrubTime: TimeInterval = 0
    @State private var runtime = DanmakuRuntime(store: InMemoryDanmakuStore())
    @State private var draft = ""
    @State private var inspected: FlyingDanmaku?

    var body: some View {
        GeometryReader { proxy in
            let artworkSide = min(proxy.size.width - 40, proxy.size.height * 0.38)
            ZStack {
                AppTheme.concertBackground.ignoresSafeArea()
                BlurredArtworkBackground(
                    url: player.current?.artworkURL,
                    seed: (player.current?.title ?? "") + (player.current?.artist ?? "empty")
                )
                .opacity(0.55)

                VStack(spacing: 14) {
                    header
                    venueLabel

                    ZStack {
                        ArtworkView(
                            url: player.current?.artworkURL,
                            seed: (player.current?.title ?? L10n.noTrack) + (player.current?.artist ?? ""),
                            cornerRadius: 18
                        )
                        .frame(width: artworkSide, height: artworkSide)
                        .shadow(color: .black.opacity(0.45), radius: 24, y: 12)

                        if player.danmakuEnabled {
                            DanmakuOverlay(items: runtime.flying, size: CGSize(width: artworkSide, height: artworkSide)) { item in
                                inspected = item
                            }
                            .frame(width: artworkSide, height: artworkSide)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .allowsHitTesting(true)
                        }
                    }

                    metadata
                    scrubber
                    transport
                    modeRow
                    danmakuBar
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
        }
        .foregroundStyle(.white)
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
        HStack {
            if showsDismiss {
                Button { player.isFullPlayerPresented = false } label: {
                    Image(systemName: "chevron.down").font(.title3.weight(.semibold))
                }
            }
            Spacer()
            Text(L10n.nowPlaying).font(.subheadline.weight(.semibold))
            Spacer()
            Button {
                player.danmakuEnabled.toggle()
            } label: {
                Image(systemName: player.danmakuEnabled ? "captions.bubble.fill" : "captions.bubble")
            }
            .accessibilityLabel(player.danmakuEnabled ? L10n.danmakuOn : L10n.danmakuOff)
        }
    }

    @ViewBuilder
    private var venueLabel: some View {
        if let tag = player.current?.venueTag, !tag.isEmpty {
            Text(tag)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.white.opacity(0.12), in: Capsule())
        }
    }

    private var metadata: some View {
        VStack(spacing: 4) {
            Text(player.current?.title ?? L10n.noTrack)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(player.current?.artist ?? L10n.pickFromLibrary)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
    }

    private var scrubber: some View {
        VStack(spacing: 6) {
            Slider(
                value: Binding(
                    get: { isScrubbing ? scrubTime : player.currentTime },
                    set: { scrubTime = $0 }
                ),
                in: 0...max(player.duration, 0.1)
            ) { editing in
                isScrubbing = editing
                if editing {
                    scrubTime = player.currentTime
                } else {
                    player.seek(to: scrubTime)
                }
            }
            .tint(.white)
            .disabled(player.current == nil)

            HStack {
                Text(TimeFormat.duration(isScrubbing ? scrubTime : player.currentTime))
                Spacer()
                Text(TimeFormat.duration(player.duration))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var transport: some View {
        HStack(spacing: 36) {
            Button { player.playPrevious() } label: {
                Image(systemName: "backward.fill").font(.title)
            }
            Button { player.togglePlayPause() } label: {
                Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 72))
            }
            .disabled(player.current == nil)
            Button { player.playNext() } label: {
                Image(systemName: "forward.fill").font(.title)
            }
        }
        .disabled(player.queue.isEmpty)
    }

    private var modeRow: some View {
        Button {
            player.cyclePlaybackMode()
        } label: {
            Label(player.playbackModeTitle, systemImage: player.playbackMode.systemImage)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.white.opacity(0.12), in: Capsule())
        }
        .accessibilityLabel(player.playbackModeTitle)
    }

    private var danmakuBar: some View {
        HStack(spacing: 8) {
            TextField(L10n.danmakuPlaceholder, text: $draft)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.white.opacity(0.12), in: Capsule())
            Button(L10n.danmakuSend) { sendDanmaku() }
                .buttonStyle(.borderedProminent)
                .disabled(player.current == nil || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func sendDanmaku() {
        guard let id = player.current?.id else { return }
        runtime.store = danmakuService
        runtime.enabled = player.danmakuEnabled
        if runtime.send(trackId: id, text: draft, currentTimeMS: player.currentTimeMS) != nil {
            draft = ""
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
                ForEach(items.filter { !$0.fading }) { item in
                    let travel = min(1, timeline.date.timeIntervalSince(item.spawnedAt) / 6.0)
                    let x = size.width - travel * (size.width + 160)
                    let y = CGFloat(item.lane) * (size.height / 3.2) + 8
                    Text(item.record.text)
                        .font(.system(size: item.record.fontSize, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                        .offset(x: x, y: y)
                        .opacity(item.fading ? 0.25 : 1)
                        .onLongPressGesture { onLongPress(item) }
                }
            }
        }
    }
}

struct FullPlayerSheet: View {
    var body: some View {
        PlayerView(showsDismiss: true)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
    }
}
