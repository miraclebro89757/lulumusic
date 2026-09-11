import SwiftUI

struct MiniPlayerBar: View {
    @Environment(PlayerEngine.self) private var player
    @Environment(AppNavigation.self) private var navigation
    var style: MiniPlayerChromeStyle = .fallbackDock

    var body: some View {
        if let current = player.current {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    HStack(spacing: 12) {
                        ArtworkView(
                            url: current.artworkURL,
                            seed: current.title + current.artist,
                            cornerRadius: 10
                        )
                        .frame(width: LoveSongTheme.Space.miniCover, height: LoveSongTheme.Space.miniCover)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(current.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(LoveSongTheme.textPrimary)
                                .lineLimit(1)
                            Text(current.artist)
                                .font(LoveSongTheme.Font.rowCaption)
                                .foregroundStyle(LoveSongTheme.textSecondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture(perform: openPlayerTab)

                    SpotlightPlayButton(
                        isPlaying: player.isPlaying,
                        enabled: true,
                        diameter: PlayerChrome.miniPlayDiameter,
                        action: { player.togglePlayPause() }
                    )
                }

                MiniProgressHint(current: player.currentTime, duration: player.duration)
            }
            .padding(.horizontal, style == .systemAccessory ? 10 : 14)
            .padding(.vertical, style == .systemAccessory ? 8 : 10)
            .frame(minHeight: style == .fallbackDock ? LoveSongTheme.Space.miniBar : 0)
            .background {
                if style == .fallbackDock {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
            }
            .overlay {
                if style == .fallbackDock {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(LoveSongTheme.hairline, lineWidth: 1)
                }
            }
            .shadow(color: style == .fallbackDock ? .black.opacity(0.35) : .clear, radius: 16, y: 6)
            .padding(.horizontal, style == .fallbackDock ? 12 : 0)
            .padding(.bottom, style == .fallbackDock ? 8 : 0)
            .scaleEffect(1)
        }
    }

    private func openPlayerTab() {
        navigation.tab = .player
    }
}

enum MiniPlayerChromeStyle {
    /// Custom glass capsule above the tab bar (iOS 17–25).
    case fallbackDock
    /// System Liquid Glass tab accessory (iOS 26+).
    case systemAccessory
}
