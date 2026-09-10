import SwiftUI

struct VenueChip: View {
    var text: String
    var compact: Bool = false

    var body: some View {
        Text(text)
            .font(LoveSongTheme.Font.chip)
            .foregroundStyle(LoveSongTheme.textPrimary)
            .lineLimit(1)
            .padding(.horizontal, compact ? 8 : 11)
            .padding(.vertical, compact ? 3 : 5)
            .overlay(
                Capsule()
                    .stroke(LoveSongTheme.spotlight.opacity(0.9), lineWidth: 1)
            )
    }
}

struct StageSurface<Content: View>: View {
    var padded: Bool = true
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padded ? 16 : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LoveSongTheme.stageElevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(LoveSongTheme.hairline, lineWidth: 1)
            )
    }
}

struct SpotlightPlayButton: View {
    var isPlaying: Bool
    var enabled: Bool = true
    var diameter: CGFloat = LoveSongTheme.Space.playButton
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(LoveSongTheme.spotlight)
                    .shadow(color: LoveSongTheme.spotlight.opacity(0.4), radius: 18, y: 8)
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

struct ConcertScrubber: View {
    var current: TimeInterval
    var duration: TimeInterval
    var enabled: Bool = true
    var onSeek: (TimeInterval) -> Void

    @State private var dragging = false
    @State private var dragValue: TimeInterval = 0

    private var shown: TimeInterval { dragging ? dragValue : current }
    private var span: TimeInterval { max(duration, 0.1) }
    private var fraction: CGFloat {
        CGFloat(min(1, max(0, shown / span)))
    }

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let thumb: CGFloat = 14
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LoveSongTheme.separator)
                        .frame(height: 3)
                    Capsule()
                        .fill(LoveSongTheme.spotlight)
                        .frame(width: max(thumb / 2, geo.size.width * fraction), height: 3)
                    Circle()
                        .fill(LoveSongTheme.spotlight)
                        .frame(width: thumb, height: thumb)
                        .shadow(color: LoveSongTheme.spotlight.opacity(0.5), radius: 6)
                        .offset(x: max(0, min(geo.size.width - thumb, geo.size.width * fraction - thumb / 2)))
                }
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(drag(in: geo.size.width))
            }
            .frame(height: 22)
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

struct StageSearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(LoveSongTheme.textTertiary)
            TextField(L10n.searchPrompt, text: $text)
                .textFieldStyle(.plain)
                .foregroundStyle(LoveSongTheme.textPrimary)
                .tint(LoveSongTheme.spotlight)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(LoveSongTheme.textTertiary)
                }
            }
        }
        .font(.subheadline)
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(LoveSongTheme.stageElevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(LoveSongTheme.hairline, lineWidth: 1)
        )
    }
}

struct QuietImportBar: View {
    var onFiles: () -> Void
    var onWifi: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onWifi) {
                HStack(spacing: 8) {
                    Image(systemName: "wifi")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(LoveSongTheme.spotlight)
                    Text(L10n.wifiImportShort)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(LoveSongTheme.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(LoveSongTheme.textTertiary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.importWebButton)

            Spacer(minLength: 8)

            Button(action: onFiles) {
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                    Text(L10n.filesImportShort)
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(LoveSongTheme.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.importFilesButton)
        }
        .padding(.vertical, 4)
    }
}

struct GlassDanmakuComposer: View {
    @Binding var text: String
    var enabled: Bool
    var focused: FocusState<Bool>.Binding
    var onSend: () -> Void

    var body: some View {
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
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(LoveSongTheme.hairline, lineWidth: 1))
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
