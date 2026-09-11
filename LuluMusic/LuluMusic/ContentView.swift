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
            .toolbarBackground(.hidden, for: .tabBar)
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

    private var tabRoot: some View {
        @Bindable var navigation = navigation
        return TabView(selection: $navigation.tab) {
            PlayerView()
                .tabItem { Label(AppTab.player.title, systemImage: AppTab.player.systemImage) }
                .tag(AppTab.player)

            LiveView()
                .tabItem { Label(AppTab.live.title, systemImage: AppTab.live.systemImage) }
                .tag(AppTab.live)

            PlaylistView()
                .tabItem { Label(AppTab.playlist.title, systemImage: AppTab.playlist.systemImage) }
                .tag(AppTab.playlist)
        }
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            LoveSongTabBar(selection: $navigation.tab)
        }
    }
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
        .environment(FavoriteStore())
        .modelContainer(container)
}
