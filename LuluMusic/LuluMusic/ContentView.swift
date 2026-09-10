import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(PlayerEngine.self) private var player
    @Environment(LibraryService.self) private var library
    @State private var tab: Tab = .library

    enum Tab: Hashable {
        case library, player, importTab
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

            ImportView()
                .tabItem { Label(L10n.tabImport, systemImage: "square.and.arrow.down") }
                .tag(Tab.importTab)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if tab == .importTab { MiniPlayerBar() }
                }
        }
        .tint(Color.accentColor)
        .sheet(isPresented: $player.isFullPlayerPresented) {
            FullPlayerSheet()
        }
        .onOpenURL { url in
            Task {
                _ = try? await library.importFile(from: url, source: .share)
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Track.self, configurations: .init(isStoredInMemoryOnly: true))
    ContentView()
        .environment(PlayerEngine())
        .environment(LibraryService(container: container))
        .modelContainer(container)
}
