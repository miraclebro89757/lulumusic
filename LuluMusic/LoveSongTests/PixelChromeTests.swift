import XCTest
@testable import LuluMusic

final class PixelChromeTests: XCTestCase {
    func testTabOrderIsPlayerLivePlaylist() {
        XCTAssertEqual(AppTab.allCases, [.player, .live, .playlist])
        XCTAssertEqual(AppTab.allCases.map(\.title), ["播放器", "现场弹幕", "歌单"])
        XCTAssertEqual(AppTab.player.systemImage, "opticaldisc")
        XCTAssertEqual(AppTab.live.systemImage, "bubble.left.and.bubble.right")
        XCTAssertEqual(AppTab.playlist.systemImage, "music.note.list")
    }

    func testFeaturedPhraseChipsMatchPixelSpec() {
        XCTAssertEqual(DanmakuPhrasePack.featured, [
            "现场封神",
            "万人大合唱",
            "这首直接泪目",
            "永远的经典"
        ])
    }

    func testConcertDateFormatsFullAndShort() {
        var components = DateComponents()
        components.year = 2025
        components.month = 8
        components.day = 16
        let date = Calendar(identifier: .gregorian).date(from: components)!
        XCTAssertEqual(ConcertDateFormat.full(date), "2025.08.16")
        XCTAssertEqual(ConcertDateFormat.short(date), "8.16")
    }

    func testLiveBubbleIdentityIsAlwaysSelf() {
        let record = DanmakuRecord(trackId: UUID(), timestampMS: 1_000, text: "现场封神")
        XCTAssertEqual(LocalDanmakuIdentity.displayName, "我")
        XCTAssertEqual(LocalDanmakuIdentity.displayName(for: record), "我")
        XCTAssertEqual(LocalDanmakuIdentity.avatarLetter(for: record), "我")
        XCTAssertFalse(LocalDanmakuIdentity.displayName.isEmpty)
    }

    func testAvatarColorSeedIsDeterministicAndLocalOnly() {
        let id = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        let first = LocalDanmakuIdentity.avatarColorSeed(for: id)
        let second = LocalDanmakuIdentity.avatarColorSeed(for: id)
        XCTAssertEqual(first, second)
        XCTAssertGreaterThanOrEqual(first, 0)
        XCTAssertLessThan(first, LocalDanmakuIdentity.avatarPalette.count)
    }
}
