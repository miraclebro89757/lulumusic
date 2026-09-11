import SwiftUI
import UIKit

struct ArtworkView: View {
    var url: URL?
    var seed: String
    var cornerRadius: CGFloat = 10

    var body: some View {
        ZStack {
            LoveSongTheme.hashGradient(for: seed)
            if let url, let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "opticaldisc")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(LoveSongTheme.textPrimary.opacity(0.85))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct ConcertStageBackground: View {
    var url: URL?
    var seed: String

    var body: some View {
        ZStack {
            LoveSongTheme.stageBackground
            CoverPalette.atmosphere(url: url, seed: seed)
            if let url, let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 56)
                    .saturation(1.5)
                    .scaleEffect(1.24)
                    .opacity(0.42)
            }
            LinearGradient(
                colors: [
                    LoveSongTheme.stageBackground.opacity(0.12),
                    LoveSongTheme.stageBackground.opacity(0.55),
                    LoveSongTheme.stageBackground.opacity(0.94)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            LoveSongTheme.dim
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
