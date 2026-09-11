import XCTest
@testable import LuluMusic

final class FavoriteStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "lovesong.favorites.test.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testTogglePersistsLikedStateForTrack() {
        let store = FavoriteStore(defaults: defaults)
        let id = UUID()
        XCTAssertFalse(store.isLiked(id))

        XCTAssertTrue(store.toggle(id))
        XCTAssertTrue(store.isLiked(id))

        let reloaded = FavoriteStore(defaults: defaults)
        XCTAssertTrue(reloaded.isLiked(id), "liked state must survive a new store instance")
    }

    func testUnlikeClearsPersistedFlag() {
        let store = FavoriteStore(defaults: defaults)
        let id = UUID()
        store.setLiked(id, true)
        store.setLiked(id, false)
        XCTAssertFalse(store.isLiked(id))

        let reloaded = FavoriteStore(defaults: defaults)
        XCTAssertFalse(reloaded.isLiked(id))
    }

    func testTracksAreIndependent() {
        let store = FavoriteStore(defaults: defaults)
        let a = UUID()
        let b = UUID()
        store.setLiked(a, true)
        XCTAssertTrue(store.isLiked(a))
        XCTAssertFalse(store.isLiked(b))
    }
}
