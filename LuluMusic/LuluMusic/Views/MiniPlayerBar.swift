import SwiftUI

enum MiniPlayerChromeStyle {
    /// Custom glass capsule above the tab bar (iOS 17–25).
    case fallbackDock
    /// System Liquid Glass tab accessory (iOS 26+).
    case systemAccessory
}

struct MiniPlayerBar: View {
    @Environment(PlayerEngine.self) private var player
    @Environment(\.selectedAppTab) private var selectedTab
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
                        .modifier(NowPlayingCoverMatch(isSource: coverIsSource, isActive: coverMatchActive))

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
                    .onTapGesture(perform: openFullPlayer)

                    SpotlightPlayButton(
                        isPlaying: player.isPlaying,
                        enabled: true,
                        diameter: PlayerChrome.miniPlayDiameter,
                        action: { player.togglePlayPause() }
                    )
                    .modifier(NowPlayingPlayMatch(isSource: coverIsSource, isActive: coverMatchActive))
                }

                MiniProgressHint(current: player.currentTime, duration: player.duration)
            }
            .padding(.horizontal, style == .systemAccessory ? 10 : 14)
            .padding(.vertical, style == .systemAccessory ? 8 : 10)
            .background {
                if style == .fallbackDock {
                    Capsule().fill(.thinMaterial)
                }
            }
            .overlay {
                if style == .fallbackDock {
                    Capsule().stroke(LoveSongTheme.hairline, lineWidth: 1)
                }
            }
            .shadow(color: style == .fallbackDock ? .black.opacity(0.35) : .clear, radius: 16, y: 6)
            .padding(.horizontal, style == .fallbackDock ? 12 : 0)
            .padding(.bottom, style == .fallbackDock ? 8 : 0)
        }
    }

    private var coverIsSource: Bool {
        NowPlayingMatchedGeometry.isSource(
            .miniPlayer,
            selectedTab: selectedTab,
            isFullPlayerPresented: player.isFullPlayerPresented
        )
    }

    private var coverMatchActive: Bool {
        NowPlayingMatchedGeometry.participates(
            .miniPlayer,
            selectedTab: selectedTab,
            isFullPlayerPresented: player.isFullPlayerPresented
        )
    }

    private func openFullPlayer() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
            player.isFullPlayerPresented = true
        }
    }
}
