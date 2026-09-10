import SwiftUI
import UIKit

struct ArtworkView: View {
    var url: URL?
    var seed: String
    var cornerRadius: CGFloat = 10

    var body: some View {
        ZStack {
            AppTheme.hashGradient(for: seed)
            if let url, let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "music.note")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .shadow(radius: 2)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct BlurredArtworkBackground: View {
    var url: URL?
    var seed: String

    var body: some View {
        ZStack {
            AppTheme.hashGradient(for: seed)
            if let url, let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
        }
        .overlay(.ultraThinMaterial)
        .overlay(Color.black.opacity(0.35))
        .ignoresSafeArea()
    }
}
