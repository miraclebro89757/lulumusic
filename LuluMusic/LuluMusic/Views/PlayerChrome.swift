import SwiftUI

enum PlayerChrome {
    static let playDiameter: CGFloat = 56
    static let skipDiameter: CGFloat = 44
    static let miniPlayDiameter: CGFloat = 44
    static let scrubberHeight: CGFloat = 4
    static let miniScrubberHeight: CGFloat = 4
    static let glassRadius: CGFloat = 16
    static let coverRadius: CGFloat = 26
}

enum AppTab: Int, CaseIterable, Hashable {
    case player
    case live
    case playlist

    var title: String {
        switch self {
        case .player: return L10n.tabPlayer
        case .live: return L10n.tabLive
        case .playlist: return L10n.tabPlaylist
        }
    }

    var systemImage: String {
        switch self {
        case .player: return "opticaldisc"
        case .live: return "bubble.left.and.bubble.right"
        case .playlist: return "music.note.list"
        }
    }
}

@Observable
final class AppNavigation {
    var tab: AppTab = .player
    var showDanmakuModal = false
}

struct ChromeGlass<Content: View>: View {
    var cornerRadius: CGFloat = PlayerChrome.glassRadius
    var inCapsule: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background {
                if inCapsule {
                    Capsule().fill(.ultraThinMaterial)
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
            }
            .overlay {
                if inCapsule {
                    Capsule().stroke(LoveSongTheme.hairline, lineWidth: 1)
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(LoveSongTheme.hairline, lineWidth: 1)
                }
            }
    }
}

struct SpotlightPlayButton: View {
    var isPlaying: Bool
    var enabled: Bool = true
    var diameter: CGFloat = PlayerChrome.playDiameter
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(LoveSongTheme.accentGlow.opacity(0.35))
                    .frame(width: diameter + 22, height: diameter + 22)
                    .blur(radius: 10)
                Circle()
                    .fill(LoveSongTheme.accent)
                    .shadow(color: LoveSongTheme.accentGlow.opacity(0.55), radius: 18, y: 0)
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: min(24, diameter * 0.42), weight: .semibold))
                    .foregroundStyle(Color.white)
                    .offset(x: isPlaying ? 0 : diameter * 0.02)
            }
            .frame(width: diameter, height: diameter)
        }
        .buttonStyle(SpotlightButtonStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
        .accessibilityLabel(isPlaying ? L10n.pause : L10n.play)
    }
}

struct LikeHeartButton: View {
    var liked: Bool
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: liked ? "heart.fill" : "heart")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(liked ? LoveSongTheme.accent : LoveSongTheme.accent.opacity(0.92))
                .shadow(color: liked ? LoveSongTheme.accentGlow.opacity(0.45) : .clear, radius: 10, y: 0)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
        .accessibilityLabel(liked ? L10n.unlike : L10n.like)
    }
}

struct SkipControlButton: View {
    var systemName: String
    var diameter: CGFloat = PlayerChrome.skipDiameter
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: diameter * 0.38, weight: .semibold))
                .foregroundStyle(LoveSongTheme.textPrimary)
                .frame(width: diameter, height: diameter)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct GlassCircleButton: View {
    var systemName: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.body.weight(.semibold))
                .foregroundStyle(LoveSongTheme.textPrimary)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(LoveSongTheme.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct ModeChip: View {
    var playbackMode: PlaybackMode
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: playbackMode.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(playbackMode == .sequential ? LoveSongTheme.textSecondary : LoveSongTheme.accent)
                .frame(minWidth: 44, minHeight: 32)
                .padding(.horizontal, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(LoveSongTheme.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct PlayerTransport: View {
    var isPlaying: Bool
    var enabled: Bool
    var liked: Bool
    var onLike: () -> Void
    var onPrevious: () -> Void
    var onPlayPause: () -> Void
    var onNext: () -> Void
    var onMore: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            LikeHeartButton(liked: liked, enabled: enabled, action: onLike)

            Spacer(minLength: 4)

            SkipControlButton(systemName: "backward.fill", action: onPrevious)
                .accessibilityLabel("上一首")

            SpotlightPlayButton(
                isPlaying: isPlaying,
                enabled: enabled,
                diameter: PlayerChrome.playDiameter,
                action: onPlayPause
            )
            .padding(.horizontal, 10)

            SkipControlButton(systemName: "forward.fill", action: onNext)
                .accessibilityLabel("下一首")

            Spacer(minLength: 4)

            Button(action: onMore) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(LoveSongTheme.textPrimary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("更多")
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 56)
        .disabled(!enabled)
    }
}

struct ConcertScrubber: View {
    var current: TimeInterval
    var duration: TimeInterval
    var peaks: [Float]
    var enabled: Bool = true
    var accent: Color = LoveSongTheme.accent
    var onSeek: (TimeInterval) -> Void

    @State private var dragging = false
    @State private var dragValue: TimeInterval = 0

    private let barCount = 52
    private var shown: TimeInterval { dragging ? dragValue : current }
    private var fraction: CGFloat {
        let span = TrackDuration.playbackSeconds(fromRaw: duration)
        guard span > 0 else { return 0 }
        return CGFloat(min(1, max(0, shown / span)))
    }

    private var bars: [Float] {
        if peaks.count == barCount { return peaks }
        if peaks.isEmpty { return Array(repeating: 0.22, count: barCount) }
        return WaveformPeakSampler.downsample(samples: peaks, barCount: barCount)
    }

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                let heights = bars
                let playhead = WaveformPeakSampler.playheadBarIndex(
                    currentMS: PlaybackClock.milliseconds(fromPlayerSeconds: shown),
                    durationMS: PlaybackClock.milliseconds(
                        fromPlayerSeconds: TrackDuration.playbackSeconds(fromRaw: duration)
                    ),
                    barCount: barCount
                )
                HStack(alignment: .center, spacing: 2) {
                    ForEach(0..<barCount, id: \.self) { index in
                        let played = index <= playhead && fraction > 0
                        Capsule()
                            .fill(played ? Color.white.opacity(0.90) : Color.white.opacity(0.15))
                            .frame(height: max(4, geo.size.height * CGFloat(0.22 + heights[index] * 0.78)))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .highPriorityGesture(drag(in: geo.size.width))
            }
            .frame(height: 28)
            .disabled(!enabled)

            HStack {
                Text(TimeFormat.duration(shown))
                Spacer()
                Text(TimeFormat.duration(duration))
            }
            .font(LoveSongTheme.Font.time)
            .foregroundStyle(LoveSongTheme.textTertiary)
        }
        .accessibilityHidden(true)
        .overlay(alignment: .center) {
            Color.clear.accessibilityLabel("进度")
        }
    }

    private func drag(in width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                dragging = true
                let command = ScrubSeek.command(
                    x: Double(value.location.x),
                    width: Double(width),
                    duration: duration
                )
                dragValue = command.seconds
                if command.shouldSeek {
                    onSeek(command.seconds)
                }
            }
            .onEnded { value in
                let command = ScrubSeek.command(
                    x: Double(value.location.x),
                    width: Double(width),
                    duration: duration
                )
                dragValue = command.seconds
                if command.shouldSeek {
                    onSeek(command.seconds)
                }
                dragging = false
            }
    }
}

struct ProgressSeekBar: View {
    var current: TimeInterval
    var duration: TimeInterval
    var enabled: Bool = true
    var onSeek: (TimeInterval) -> Void

    @State private var dragging = false
    @State private var dragValue: TimeInterval = 0

    private var shown: TimeInterval { dragging ? dragValue : current }
    private var fraction: CGFloat {
        let span = TrackDuration.playbackSeconds(fromRaw: duration)
        guard span > 0 else { return 0 }
        return CGFloat(min(1, max(0, shown / span)))
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(TimeFormat.duration(shown))
                Spacer()
                Text(TimeFormat.duration(duration))
            }
            .font(LoveSongTheme.Font.time)
            .foregroundStyle(LoveSongTheme.textTertiary)

            GeometryReader { geo in
                let knob = LoveSongTheme.Space.progressKnob
                let trackH = LoveSongTheme.Space.progressTrack
                let x = max(knob / 2, min(geo.size.width - knob / 2, geo.size.width * fraction))
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.14))
                        .frame(height: trackH)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [LoveSongTheme.accent, LoveSongTheme.accentBright],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(trackH, x), height: trackH)
                    Circle()
                        .fill(Color.white)
                        .frame(width: dragging ? knob + 4 : knob, height: dragging ? knob + 4 : knob)
                        .shadow(color: LoveSongTheme.accentGlow.opacity(0.5), radius: 10, y: 0)
                        .offset(x: x - knob / 2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .highPriorityGesture(drag(in: geo.size.width))
            }
            .frame(height: 22)
            .disabled(!enabled)
            .opacity(enabled ? 1 : 0.4)
        }
    }

    private func drag(in width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                dragging = true
                let command = ScrubSeek.command(
                    x: Double(value.location.x),
                    width: Double(width),
                    duration: duration
                )
                dragValue = command.seconds
                if command.shouldSeek {
                    onSeek(command.seconds)
                }
            }
            .onEnded { value in
                let command = ScrubSeek.command(
                    x: Double(value.location.x),
                    width: Double(width),
                    duration: duration
                )
                dragValue = command.seconds
                if command.shouldSeek {
                    onSeek(command.seconds)
                }
                dragging = false
            }
    }
}

struct MiniProgressHint: View {
    var current: TimeInterval
    var duration: TimeInterval

    var body: some View {
        GeometryReader { geo in
            let fraction = {
                let span = TrackDuration.playbackSeconds(fromRaw: duration)
                guard span > 0 else { return CGFloat(0) }
                return CGFloat(min(1, max(0, current / span)))
            }()
            ZStack(alignment: .leading) {
                Capsule().fill(LoveSongTheme.separator)
                Capsule()
                    .fill(LoveSongTheme.accent)
                    .frame(width: max(PlayerChrome.miniScrubberHeight, geo.size.width * fraction))
            }
        }
        .frame(height: PlayerChrome.miniScrubberHeight)
    }
}

struct GlassDanmakuComposer: View {
    @Binding var text: String
    var enabled: Bool
    var focused: FocusState<Bool>.Binding
    var onSend: () -> Void
    var onSmile: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            TextField(L10n.danmakuPlaceholder, text: $text)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .foregroundStyle(LoveSongTheme.textPrimary)
                .focused(focused)
                .submitLabel(.send)
                .disabled(!enabled)
                .onSubmit(onSend)
                .accessibilityLabel(L10n.danmakuPlaceholder)
            if let onSmile {
                Button(action: onSmile) {
                    Image(systemName: "face.smiling")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(LoveSongTheme.textPrimary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .disabled(!enabled)
                .accessibilityLabel(L10n.danmakuSmile)
            }
            Button(action: onSend) {
                Text(L10n.danmakuSend)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(LoveSongTheme.accent, in: Capsule())
            }
            .disabled(!enabled || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(enabled && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 1 : 0.35)
            .accessibilityLabel(L10n.danmakuSend)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(minHeight: 48)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LoveSongTheme.danmakuBarFill.opacity(0.55))
                }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LoveSongTheme.hairline, lineWidth: 1)
        )
    }
}
