import SwiftUI

enum PlayerChrome {
    static let playDiameter: CGFloat = 58
    static let skipDiameter: CGFloat = 46
    static let miniPlayDiameter: CGFloat = 36
    static let scrubberHeight: CGFloat = 6
    static let miniScrubberHeight: CGFloat = 4
    static let glassRadius: CGFloat = 24
    static let coverRadius: CGFloat = 24
    static let coverMatchID = "nowPlayingCover"
    static let playMatchID = "nowPlayingPlay"
}

enum AppTab: Hashable {
    case library, player
}

private struct ConcertNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

private struct SelectedAppTabKey: EnvironmentKey {
    static let defaultValue: AppTab = .library
}

extension EnvironmentValues {
    var concertNamespace: Namespace.ID? {
        get { self[ConcertNamespaceKey.self] }
        set { self[ConcertNamespaceKey.self] = newValue }
    }

    var selectedAppTab: AppTab {
        get { self[SelectedAppTabKey.self] }
        set { self[SelectedAppTabKey.self] = newValue }
    }
}

struct NowPlayingCoverMatch: ViewModifier {
    var isSource: Bool

    @Environment(\.concertNamespace) private var concertNamespace

    func body(content: Content) -> some View {
        if let concertNamespace {
            content.matchedGeometryEffect(
                id: PlayerChrome.coverMatchID,
                in: concertNamespace,
                properties: .frame,
                isSource: isSource
            )
        } else {
            content
        }
    }
}

struct NowPlayingPlayMatch: ViewModifier {
    var isSource: Bool

    @Environment(\.concertNamespace) private var concertNamespace

    func body(content: Content) -> some View {
        if let concertNamespace {
            content.matchedGeometryEffect(
                id: PlayerChrome.playMatchID,
                in: concertNamespace,
                properties: .frame,
                isSource: isSource
            )
        } else {
            content
        }
    }
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
                    .fill(LoveSongTheme.spotlight)
                    .shadow(color: LoveSongTheme.spotlight.opacity(0.38), radius: diameter * 0.22, y: 6)
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: diameter * 0.34, weight: .semibold))
                    .foregroundStyle(LoveSongTheme.stageBackground)
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
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(LoveSongTheme.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct PlayerTransport: View {
    var isPlaying: Bool
    var enabled: Bool
    var playbackMode: PlaybackMode
    var modeTitle: String
    var onMode: () -> Void
    var onPrevious: () -> Void
    var onPlayPause: () -> Void
    var onNext: () -> Void
    var playIsSource: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onMode) {
                Image(systemName: playbackMode.systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(playbackMode == .sequential ? LoveSongTheme.textTertiary : LoveSongTheme.spotlight)
                    .frame(width: 40, height: 40)
            }
            .accessibilityLabel(modeTitle)

            Spacer(minLength: 8)

            SkipControlButton(systemName: "backward.fill", action: onPrevious)
                .accessibilityLabel("上一首")

            SpotlightPlayButton(
                isPlaying: isPlaying,
                enabled: enabled,
                diameter: PlayerChrome.playDiameter,
                action: onPlayPause
            )
            .modifier(NowPlayingPlayMatch(isSource: playIsSource))
            .padding(.horizontal, 16)

            SkipControlButton(systemName: "forward.fill", action: onNext)
                .accessibilityLabel("下一首")

            Spacer(minLength: 8)
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: PlayerChrome.glassRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: PlayerChrome.glassRadius, style: .continuous)
                        .fill(Color.black.opacity(0.22))
                }
                .shadow(color: .black.opacity(0.32), radius: 18, y: 10)
        }
        .overlay(
            RoundedRectangle(cornerRadius: PlayerChrome.glassRadius, style: .continuous)
                .stroke(LoveSongTheme.hairline, lineWidth: 1)
        )
        .disabled(!enabled)
    }
}

struct ConcertScrubber: View {
    var current: TimeInterval
    var duration: TimeInterval
    var enabled: Bool = true
    var seed: String = ""
    var accent: Color = LoveSongTheme.spotlight
    var onSeek: (TimeInterval) -> Void

    @State private var dragging = false
    @State private var dragValue: TimeInterval = 0

    private let barCount = 52
    private var shown: TimeInterval { dragging ? dragValue : current }
    private var span: TimeInterval { max(duration, 0.1) }
    private var fraction: CGFloat {
        CGFloat(min(1, max(0, shown / span)))
    }

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                let heights = Self.bars(seed: seed, count: barCount)
                HStack(alignment: .center, spacing: 2) {
                    ForEach(0..<barCount, id: \.self) { index in
                        let played = CGFloat(index) / CGFloat(barCount) <= fraction
                        Capsule()
                            .fill(played ? accent : LoveSongTheme.textTertiary.opacity(0.42))
                            .frame(height: max(4, geo.size.height * heights[index]))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .gesture(drag(in: geo.size.width))
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
    }

    private static func bars(seed: String, count: Int) -> [CGFloat] {
        var hasher = Hasher()
        hasher.combine(seed)
        var value = hasher.finalize()
        return (0..<count).map { i in
            value = value &* 16_777_619 &+ i
            let n = Int(UInt(bitPattern: value) % 100)
            return 0.26 + CGFloat(n) / 100 * 0.74
        }
    }

    private func drag(in width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                dragging = true
                let x = min(max(0, value.location.x), width)
                dragValue = span * Double(x / max(width, 1))
            }
            .onEnded { value in
                let x = min(max(0, value.location.x), width)
                onSeek(span * Double(x / max(width, 1)))
                dragging = false
            }
    }
}

struct MiniProgressHint: View {
    var current: TimeInterval
    var duration: TimeInterval

    var body: some View {
        GeometryReader { geo in
            let fraction = duration > 0 ? min(1, max(0, current / duration)) : 0
            ZStack(alignment: .leading) {
                Capsule().fill(LoveSongTheme.separator)
                Capsule()
                    .fill(LoveSongTheme.spotlight)
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

    @State private var lift: CGFloat = 0
    @GestureState private var dragLift: CGFloat = 0

    var body: some View {
        VStack(spacing: 8) {
            Capsule()
                .fill(Color.white.opacity(0.32))
                .frame(width: 36, height: 4)
                .padding(.top, 6)
                .padding(.bottom, 2)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .gesture(drag, including: focused.wrappedValue ? .none : .gesture)
                .accessibilityHidden(true)
            HStack(spacing: 10) {
                TextField(L10n.danmakuPlaceholder, text: $text)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .foregroundStyle(LoveSongTheme.textPrimary)
                    .focused(focused)
                    .submitLabel(.send)
                    .onSubmit(onSend)
                Button(action: onSend) {
                    Text(L10n.danmakuSend)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(LoveSongTheme.stageBackground)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(LoveSongTheme.spotlight, in: Capsule())
                }
                .disabled(!enabled || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(enabled && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 1 : 0.35)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
        .background {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule(style: .continuous)
                        .fill(LoveSongTheme.danmakuBarFill.opacity(0.55))
                }
        }
        .overlay(
            Capsule(style: .continuous)
                .stroke(LoveSongTheme.hairline, lineWidth: 1)
        )
        .offset(y: focused.wrappedValue ? 0 : lift + dragLift)
        .onChange(of: focused.wrappedValue) { _, on in
            if on {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) { lift = 0 }
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: lift)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 8)
            .updating($dragLift) { value, state, _ in
                state = min(20, max(-150, value.translation.height))
            }
            .onEnded { value in
                let next = min(0, max(-150, lift + value.translation.height))
                lift = next > -20 ? 0 : next
            }
    }
}
