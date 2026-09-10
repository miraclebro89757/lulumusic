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
                        .blur(radius: 54)
                        .saturation(1.55)
                        .scaleEffect(1.22)
                } else {
                    LoveSongTheme.hashGradient(for: seed)
                }
            }
            .opacity(0.78)
            .overlay {
                LinearGradient(
                    colors: [
                        LoveSongTheme.stageBackground.opacity(0.08),
                        LoveSongTheme.stageBackground.opacity(0.45),
                        LoveSongTheme.stageBackground.opacity(0.92)
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
