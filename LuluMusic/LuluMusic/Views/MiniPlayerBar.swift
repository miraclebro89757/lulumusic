import SwiftUI

struct MiniPlayerBar: View {
    @Environment(PlayerEngine.self) private var player

    var body: some View {
        if let current = player.current {
            VStack(spacing: 0) {
                GeometryReader { geo in
                    let fraction = player.duration > 0 ? min(1, max(0, player.currentTime / player.duration)) : 0
                    ZStack(alignment: .leading) {
                        Rectangle().fill(LoveSongTheme.separator)
                        Rectangle()
                            .fill(LoveSongTheme.spotlight)
                            .frame(width: geo.size.width * fraction)
                    }
                }
                .frame(height: 2)

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
                    .onTapGesture {
                        player.isFullPlayerPresented = true
                    }

                    Button {
                        player.togglePlayPause()
                    } label: {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(LoveSongTheme.stageBackground)
                            .frame(width: 36, height: 36)
                            .background(LoveSongTheme.spotlight, in: Circle())
                    }
                    .buttonStyle(SpotlightButtonStyle())
                    .accessibilityLabel(player.isPlaying ? L10n.pause : L10n.play)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(LoveSongTheme.hairline, lineWidth: 1)
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
        }
    }
}
