import SwiftUI
import UIKit

/// Black-purple-white design tokens. UI-only; Core logic does not depend on this.
enum LoveSongTheme {
    static let stageBackground = Color(hex: 0x09060F)
    static let stageElevated = Color(hex: 0x0E0A17)
    static let accent = Color(hex: 0x8B5CF6)
    static let accentPressed = Color(hex: 0x7C3AED)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.64)
    static let textTertiary = Color.white.opacity(0.40)
    static let danmaku = Color.white.opacity(0.92)
    static let danmakuAccent = Color(hex: 0x8B5CF6).opacity(0.92)
    static let danmakuFlyStroke = Color(hex: 0x8B5CF6).opacity(0.35)
    static let separator = Color.white.opacity(0.08)
    static let hairline = Color.white.opacity(0.12)
    static let dim = Color.black.opacity(0.40)
    static let coverShadow = Color.black.opacity(0.45)
    static let danmakuBarFill = Color.black.opacity(0.55)
    static let bubbleFill = Color.black.opacity(0.55)
    static let error = Color(hex: 0xFF453A)
    static let success = Color(hex: 0x30D158)
    static let glassFill = Color.white.opacity(0.06)
    static let liveFallbackBottom = Color(hex: 0x2E1065)

    enum Font {
        static let playerTitle = SwiftUI.Font.system(size: 22, weight: .bold)
        static let playerArtist = SwiftUI.Font.system(size: 16, weight: .regular)
        static let rowTitle = SwiftUI.Font.system(size: 16, weight: .medium)
        static let rowCaption = SwiftUI.Font.system(size: 13, weight: .regular)
        static let time = SwiftUI.Font.system(size: 12, weight: .regular).monospacedDigit()
        static let chip = SwiftUI.Font.system(size: 12, weight: .semibold)
        static let wordmark = SwiftUI.Font.system(size: 20, weight: .bold)
        static let emptyTitle = SwiftUI.Font.system(size: 22, weight: .semibold)
        static let pairing = SwiftUI.Font.system(size: 32, weight: .bold).monospacedDigit()
        static let sheetTitle = SwiftUI.Font.system(size: 20, weight: .bold)
        static let body = SwiftUI.Font.system(size: 16, weight: .regular)
    }

    enum Space {
        static let rowCover: CGFloat = 56
        static let playButton: CGFloat = 56
        static let skipButton: CGFloat = 44
        static let miniCover: CGFloat = 40
        static let screen: CGFloat = 16
        static let stack: CGFloat = 12
        static let heroEmpty: CGFloat = 72
        static let coverMax: CGFloat = 290
        static let progressTrack: CGFloat = 6
        static let progressKnob: CGFloat = 16
        static let miniBar: CGFloat = 64
    }

    static var stageFill: some View {
        stageBackground.ignoresSafeArea()
    }

    static func hashGradient(for seed: String) -> LinearGradient {
        var hasher = Hasher()
        hasher.combine(seed)
        let value = abs(hasher.finalize())
        let hue = Double(value % 18) / 360.0 + 0.72
        return LinearGradient(
            colors: [
                Color(hue: hue, saturation: 0.58, brightness: 0.34),
                liveFallbackBottom,
                stageBackground
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static func applyChrome() {
        let tab = UITabBarAppearance()
        tab.configureWithDefaultBackground()
        tab.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        tab.backgroundColor = UIColor(stageElevated).withAlphaComponent(0.92)
        tab.shadowColor = UIColor.white.withAlphaComponent(0.08)
        let item = UITabBarItemAppearance()
        item.normal.iconColor = UIColor(textSecondary)
        item.normal.titleTextAttributes = [
            .foregroundColor: UIColor(textSecondary),
            .font: UIFont.systemFont(ofSize: 12, weight: .regular)
        ]
        item.selected.iconColor = UIColor(accent)
        item.selected.titleTextAttributes = [
            .foregroundColor: UIColor(accent),
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold)
        ]
        tab.stackedLayoutAppearance = item
        tab.inlineLayoutAppearance = item
        tab.compactInlineLayoutAppearance = item
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
        UITabBar.appearance().tintColor = UIColor(accent)

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(stageBackground)
        nav.shadowColor = .clear
        nav.largeTitleTextAttributes = [
            .foregroundColor: UIColor(textPrimary),
            .font: UIFont.systemFont(ofSize: 22, weight: .bold)
        ]
        nav.titleTextAttributes = [
            .foregroundColor: UIColor(textPrimary),
            .font: UIFont.systemFont(ofSize: 20, weight: .bold)
        ]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = UIColor(accent)
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [
            .foregroundColor: UIColor(textPrimary)
        ]
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

struct SpotlightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.62), value: configuration.isPressed)
    }
}
