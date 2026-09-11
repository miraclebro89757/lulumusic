import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(PlayerEngine.self) private var player
    @Environment(LibraryService.self) private var library
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab: AppTab = .library
    @Namespace private var concertNS

    var body: some View {
        @Bindable var player = player
        ZStack {
            tabRoot
            if player.isFullPlayerPresented {
                FullPlayerOverlay()
                    .transition(.identity)
                    .zIndex(2)
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.84), value: player.isFullPlayerPresented)
        .environment(\.concertNamespace, concertNS)
        .environment(\.selectedAppTab, tab)
        .tint(LoveSongTheme.spotlight)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
        .onOpenURL { url in
            guard IncomingTransfer.shouldImport(url: url) else { return }
            Task {
                _ = try? await library.importFile(from: url, source: .share)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                player.persistResume()
                if let id = player.current?.id {
                    library.updateLastPosition(trackID: id, positionMS: player.currentTimeMS)
                }
            }
        }
    }

    @ViewBuilder
    private var tabRoot: some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            liquidGlassTabs
        } else {
            legacyTabs
        }
        #else
        legacyTabs
        #endif
    }

    private var legacyTabs: some View {
        TabView(selection: $tab) {
            LibraryView()
                .tabItem { Label(L10n.tabLibrary, systemImage: "music.note.list") }
                .tag(AppTab.library)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if tab == .library {
                        MiniPlayerBar(style: .fallbackDock)
                            .opacity(player.isFullPlayerPresented ? 0 : 1)
                            .allowsHitTesting(!player.isFullPlayerPresented)
                            .accessibilityHidden(player.isFullPlayerPresented)
                    }
                }

            PlayerView()
                .tabItem { Label(L10n.tabPlayer, systemImage: "play.circle.fill") }
                .tag(AppTab.player)
        }
    }

    #if compiler(>=6.2)
    @available(iOS 26.0, *)
    private var liquidGlassTabs: some View {
        TabView(selection: $tab) {
            LibraryView()
                .tabItem { Label(L10n.tabLibrary, systemImage: "music.note.list") }
                .tag(AppTab.library)

            PlayerView()
                .tabItem { Label(L10n.tabPlayer, systemImage: "play.circle.fill") }
                .tag(AppTab.player)
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            if tab == .library, player.current != nil {
                MiniPlayerBar(style: .systemAccessory)
                    .opacity(player.isFullPlayerPresented ? 0 : 1)
                    .allowsHitTesting(!player.isFullPlayerPresented)
                    .accessibilityHidden(player.isFullPlayerPresented)
            }
        }
    }
    #endif
}

#Preview {
    let container = try! ModelContainer(
        for: Track.self, DanmakuComment.self,
        configurations: .init(isStoredInMemoryOnly: true)
    )
    ContentView()
        .environment(PlayerEngine())
        .environment(LibraryService(container: container))
        .environment(DanmakuService(container: container))
        .modelContainer(container)
}
