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
                Image(systemName: "music.note")
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
            Group {
                if let url, let image = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .blur(radius: 48)
                        .saturation(1.4)
                        .scaleEffect(1.18)
                } else {
                    LoveSongTheme.hashGradient(for: seed)
                }
            }
            .opacity(0.62)
            .overlay {
                LinearGradient(
                    colors: [
                        LoveSongTheme.stageBackground.opacity(0.15),
                        LoveSongTheme.stageBackground.opacity(0.72),
                        LoveSongTheme.stageBackground
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .overlay(LoveSongTheme.dim)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
