import SwiftUI
import UIKit

enum ReferenceArt {
    static let albumPlaceholder = "album_night_we_met"
    static let liveStage = "concert_live_stage"
}

struct ArtworkView: View {
    var url: URL?
    var seed: String
    var cornerRadius: CGFloat = 10
    var placeholderAsset: String? = ReferenceArt.albumPlaceholder

    var body: some View {
        ZStack {
            LoveSongTheme.hashGradient(for: seed)
            if let url, let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let placeholderAsset, UIImage(named: placeholderAsset) != nil {
                Image(placeholderAsset)
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
    var fallbackAsset: String? = ReferenceArt.liveStage
    var dim: Double = 0.38

    var body: some View {
        ZStack {
            LoveSongTheme.stageBackground
            CoverPalette.atmosphere(url: url, seed: seed)
            artwork
                .resizable()
                .scaledToFill()
                .blur(radius: url == nil ? 0 : 28)
                .saturation(1.35)
                .scaleEffect(url == nil ? 1.02 : 1.18)
                .opacity(url == nil ? 1 : 0.72)
            LoveSongTheme.stageBackground.opacity(dim)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var artwork: Image {
        if let url, let image = UIImage(contentsOfFile: url.path) {
            return Image(uiImage: image)
        }
        if let fallbackAsset, UIImage(named: fallbackAsset) != nil {
            return Image(fallbackAsset)
        }
        return Image(systemName: "photo")
    }
}
