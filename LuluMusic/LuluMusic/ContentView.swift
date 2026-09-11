import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(PlayerEngine.self) private var player
    @Environment(LibraryService.self) private var library
    @Environment(\.scenePhase) private var scenePhase
    @State private var navigation = AppNavigation()

    var body: some View {
        tabRoot
            .environment(navigation)
            .tint(LoveSongTheme.accent)
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
        @Bindable var navigation = navigation
        return TabView(selection: $navigation.tab) {
            PlaylistView()
                .tabItem { Label(L10n.tabPlaylist, systemImage: "list.music") }
                .tag(AppTab.playlist)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if navigation.tab == .playlist {
                        MiniPlayerBar(style: .fallbackDock)
                    }
                }

            PlayerView()
                .tabItem { Label(L10n.tabPlayer, systemImage: "opticaldisc") }
                .tag(AppTab.player)

            LiveView()
                .tabItem { Label(L10n.tabLive, systemImage: "bubble.left.and.bubble.right") }
                .tag(AppTab.live)
        }
    }

    #if compiler(>=6.2)
    @available(iOS 26.0, *)
    private var liquidGlassTabs: some View {
        @Bindable var navigation = navigation
        return TabView(selection: $navigation.tab) {
            PlaylistView()
                .tabItem { Label(L10n.tabPlaylist, systemImage: "list.music") }
                .tag(AppTab.playlist)

            PlayerView()
                .tabItem { Label(L10n.tabPlayer, systemImage: "opticaldisc") }
                .tag(AppTab.player)

            LiveView()
                .tabItem { Label(L10n.tabLive, systemImage: "bubble.left.and.bubble.right") }
                .tag(AppTab.live)
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            if navigation.tab == .playlist, player.current != nil {
                MiniPlayerBar(style: .systemAccessory)
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
