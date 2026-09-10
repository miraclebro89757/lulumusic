import SwiftData
import SwiftUI

@main
struct LuluMusicApp: App {
    private let container: ModelContainer
    @State private var player: PlayerEngine
    @State private var library: LibraryService

    init() {
        let schema = Schema([Track.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("无法创建曲库存储：\(error)")
        }
        let library = LibraryService(container: container)
        _library = State(initialValue: library)
        _player = State(initialValue: PlayerEngine())
        try? LibraryPaths.ensureDirectories()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(player)
                .environment(library)
                .preferredColorScheme(nil)
        }
        .modelContainer(container)
    }
}
