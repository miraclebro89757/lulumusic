import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(PlayerEngine.self) private var player
    @Environment(LibraryService.self) private var library
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab: Tab = .library

    enum Tab: Hashable {
        case library, player
    }

    var body: some View {
        @Bindable var player = player
        TabView(selection: $tab) {
            LibraryView()
                .tabItem { Label(L10n.tabLibrary, systemImage: "music.note.list") }
                .tag(Tab.library)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if tab == .library { MiniPlayerBar() }
                }

            PlayerView()
                .tabItem { Label(L10n.tabPlayer, systemImage: "play.circle.fill") }
                .tag(Tab.player)
        }
        .tint(Color.accentColor)
        .sheet(isPresented: $player.isFullPlayerPresented) {
            FullPlayerSheet()
        }
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
