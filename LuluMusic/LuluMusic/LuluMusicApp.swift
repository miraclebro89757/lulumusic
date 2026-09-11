import SwiftData
import SwiftUI

@main
struct LoveSongApp: App {
    private let container: ModelContainer
    @State private var player: PlayerEngine
    @State private var library: LibraryService
    @State private var danmaku: DanmakuService
    @State private var favorites: FavoriteStore

    init() {
        let schema = Schema([Track.self, DanmakuComment.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("无法创建演唱会回忆存储：\(error)")
        }
        let library = LibraryService(container: container)
        _library = State(initialValue: library)
        _player = State(initialValue: PlayerEngine())
        _danmaku = State(initialValue: DanmakuService(container: container))
        _favorites = State(initialValue: FavoriteStore())
        try? LibraryPaths.ensureDirectories()
        LoveSongTheme.applyChrome()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(player)
                .environment(library)
                .environment(danmaku)
                .environment(favorites)
                .preferredColorScheme(.dark)
                .task {
                    player.restoreSession(library: library.allTracks())
                }
        }
        .modelContainer(container)
    }
}
