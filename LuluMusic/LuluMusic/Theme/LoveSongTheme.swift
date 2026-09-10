import SwiftUI
import UIKit

/// Concert-stage design tokens. UI-only; Core logic does not depend on this.
enum LoveSongTheme {
    static let stageBackground = Color(hex: 0x0A0A0C)
    static let stageElevated = Color(hex: 0x141418)
    static let spotlight = Color(hex: 0xFF8A3D)
    static let textPrimary = Color(hex: 0xF5F5F7)
    static let textSecondary = Color(hex: 0x9A9AA3)
    static let textTertiary = Color(hex: 0x5C5C66)
    static let danmaku = Color.white.opacity(0.94)
    static let danmakuAccent = Color(hex: 0xFF8A3D).opacity(0.92)
    static let separator = Color.white.opacity(0.07)
    static let hairline = Color.white.opacity(0.08)
    static let dim = Color.black.opacity(0.45)
    static let coverShadow = Color.black.opacity(0.55)

    enum Font {
        static let playerTitle = SwiftUI.Font.system(size: 28, weight: .bold, design: .rounded)
        static let playerArtist = SwiftUI.Font.system(size: 16, weight: .regular)
        static let rowTitle = SwiftUI.Font.system(size: 16, weight: .medium)
        static let rowCaption = SwiftUI.Font.system(size: 13, weight: .regular)
        static let time = SwiftUI.Font.system(size: 11, weight: .medium, design: .rounded).monospacedDigit()
        static let chip = SwiftUI.Font.system(size: 12, weight: .semibold)
        static let wordmark = SwiftUI.Font.system(size: 15, weight: .semibold, design: .rounded)
        static let emptyTitle = SwiftUI.Font.system(size: 22, weight: .semibold, design: .rounded)
        static let pairing = SwiftUI.Font.system(size: 40, weight: .bold, design: .rounded).monospacedDigit()
    }

    enum Space {
        static let rowCover: CGFloat = 56
        static let playButton: CGFloat = 74
        static let miniCover: CGFloat = 44
        static let screen: CGFloat = 20
        static let stack: CGFloat = 16
    }

    static var stageFill: some View {
        stageBackground.ignoresSafeArea()
    }

    static func hashGradient(for seed: String) -> LinearGradient {
        var hasher = Hasher()
        hasher.combine(seed)
        let value = abs(hasher.finalize())
        let hue = Double(value % 40) / 360.0 + 0.04
        return LinearGradient(
            colors: [
                Color(hue: hue, saturation: 0.42, brightness: 0.28),
                Color(hue: hue + 0.06, saturation: 0.55, brightness: 0.18),
                stageBackground
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func applyChrome() {
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(stageElevated)
        tab.shadowColor = UIColor.white.withAlphaComponent(0.06)
        let item = UITabBarItemAppearance()
        item.normal.iconColor = UIColor(textTertiary)
        item.normal.titleTextAttributes = [.foregroundColor: UIColor(textTertiary)]
        item.selected.iconColor = UIColor(spotlight)
        item.selected.titleTextAttributes = [.foregroundColor: UIColor(spotlight)]
        tab.stackedLayoutAppearance = item
        tab.inlineLayoutAppearance = item
        tab.compactInlineLayoutAppearance = item
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
        UITabBar.appearance().tintColor = UIColor(spotlight)

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(stageBackground)
        nav.shadowColor = .clear
        nav.largeTitleTextAttributes = [
            .foregroundColor: UIColor(textPrimary),
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        nav.titleTextAttributes = [.foregroundColor: UIColor(textPrimary)]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = UIColor(spotlight)
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
            .scaleEffect(configuration.isPressed ? 0.90 : 1)
            .animation(.spring(response: 0.30, dampingFraction: 0.58), value: configuration.isPressed)
    }
}
