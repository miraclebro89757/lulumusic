import SwiftUI

struct PlayerView: View {
    @Environment(PlayerEngine.self) private var player
    var showsDismiss = false

    @State private var isScrubbing = false
    @State private var scrubTime: TimeInterval = 0

    var body: some View {
        GeometryReader { proxy in
            let artworkSide = min(proxy.size.width - 48, proxy.size.height * 0.42)
            ZStack {
                BlurredArtworkBackground(
                    url: player.current?.artworkURL,
                    seed: (player.current?.title ?? "") + (player.current?.artist ?? "empty")
                )

                VStack(spacing: 20) {
                    header
                    Spacer(minLength: 8)

                    ArtworkView(
                        url: player.current?.artworkURL,
                        seed: (player.current?.title ?? L10n.noTrack) + (player.current?.artist ?? ""),
                        cornerRadius: 22
                    )
                    .frame(width: artworkSide, height: artworkSide)
                    .shadow(color: .black.opacity(0.35), radius: 24, y: 12)

                    metadata
                    scrubber
                    transport
                    modeRow
                    queuePreview
                    Spacer(minLength: 4)
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
        }
        .foregroundStyle(.white)
    }

    private var header: some View {
        HStack {
            if showsDismiss {
                Button {
                    player.isFullPlayerPresented = false
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.title3.weight(.semibold))
                        .frame(width: 36, height: 36)
                }
            } else {
                Image(systemName: "music.note.list")
                    .font(.title3)
                    .frame(width: 36, height: 36)
                    .opacity(0.7)
            }
            Spacer()
            Text(L10n.nowPlaying)
                .font(.subheadline.weight(.semibold))
                .opacity(0.9)
            Spacer()
            Text(player.playbackModeTitle)
                .font(.caption)
                .opacity(0.7)
                .frame(minWidth: 36, alignment: .trailing)
        }
    }

    private var metadata: some View {
        VStack(spacing: 6) {
            Text(player.current?.title ?? L10n.noTrack)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(player.current.map { "\($0.artist) · \($0.album)" } ?? L10n.pickFromLibrary)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .lineLimit(2)
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
            .accessibilityLabel(player.isPlaying ? L10n.pause : L10n.play)
            Button { player.playNext() } label: {
                Image(systemName: "forward.fill").font(.title)
            }
        }
        .disabled(player.queue.isEmpty)
    }

    private var modeRow: some View {
        HStack(spacing: 28) {
            Button {
                player.toggleShuffle()
            } label: {
                Image(systemName: "shuffle")
                    .foregroundStyle(player.isShuffle ? Color.accentColor : .white.opacity(0.85))
                    .opacity(player.isShuffle ? 1 : 0.7)
            }
            .accessibilityLabel(L10n.shuffle)

            Button {
                player.cycleRepeatMode()
            } label: {
                Image(systemName: player.repeatMode.systemImage)
                    .foregroundStyle(player.repeatMode == .off ? .white.opacity(0.7) : Color.accentColor)
            }
            .accessibilityLabel(player.repeatMode.title)

            Text(player.isShuffle ? L10n.shuffle : player.repeatMode == .off ? L10n.sequential : player.repeatMode.title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .font(.title3)
        .padding(.top, 4)
    }

    @ViewBuilder
    private var queuePreview: some View {
        if player.queue.count > 1 {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.upNext)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                ForEach(Array(player.queue.enumerated().prefix(4)), id: \.element.id) { index, item in
                    Button {
                        player.jumpToQueueIndex(index)
                    } label: {
                        HStack {
                            Text("\(index + 1)")
                                .font(.caption.monospacedDigit())
                                .frame(width: 18)
                            Text(item.title)
                                .lineLimit(1)
                            Spacer()
                            if index == player.currentIndex {
                                Image(systemName: "waveform")
                            }
                        }
                        .font(.footnote)
                        .foregroundStyle(index == player.currentIndex ? Color.accentColor : .white.opacity(0.86))
                    }
                }
            }
            .padding(12)
            .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

struct FullPlayerSheet: View {
    var body: some View {
        PlayerView(showsDismiss: true)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(.clear)
    }
}
