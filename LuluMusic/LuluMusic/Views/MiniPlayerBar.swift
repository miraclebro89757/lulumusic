import SwiftUI

struct MiniPlayerBar: View {
    @Environment(PlayerEngine.self) private var player

    var body: some View {
        if let current = player.current {
            VStack(spacing: 0) {
                GeometryReader { geo in
                    let fraction = player.duration > 0 ? min(1, max(0, player.currentTime / player.duration)) : 0
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: geo.size.width * fraction, height: 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 2)

                HStack(spacing: 12) {
                    ArtworkView(url: current.artworkURL, seed: current.title + current.artist, cornerRadius: 8)
                        .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(current.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Text(current.artist)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    Button {
                        player.togglePlayPause()
                    } label: {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title3)
                            .frame(width: 36, height: 36)
                    }
                    .accessibilityLabel(player.isPlaying ? L10n.pause : L10n.play)

                    Button {
                        player.playNext()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                            .frame(width: 36, height: 36)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 10, y: 2)
            .padding(.horizontal, 10)
            .padding(.bottom, 6)
            .contentShape(Rectangle())
            .onTapGesture {
                player.isFullPlayerPresented = true
            }
        }
    }
}
