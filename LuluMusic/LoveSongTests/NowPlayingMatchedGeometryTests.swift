import XCTest
@testable import LuluMusic

final class NowPlayingMatchedGeometryTests: XCTestCase {
    func testAtMostOneSourceForEveryPresentationState() {
        for tab in [AppTab.library, .player] {
            for presented in [false, true] {
                let sources = NowPlayingMatchSurface.allCases.filter {
                    NowPlayingMatchedGeometry.isSource(
                        $0,
                        selectedTab: tab,
                        isFullPlayerPresented: presented
                    )
                }
                XCTAssertLessThanOrEqual(
                    sources.count,
                    1,
                    "multiple isSource true: tab=\(tab) presented=\(presented) sources=\(sources)"
                )
            }
        }
    }

    func testMiniIsSourceOnlyOnLibraryWhenCollapsed() {
        XCTAssertTrue(source(.miniPlayer, tab: .library, presented: false))
        XCTAssertFalse(source(.miniPlayer, tab: .library, presented: true))
        XCTAssertFalse(source(.miniPlayer, tab: .player, presented: false))
        XCTAssertFalse(source(.miniPlayer, tab: .player, presented: true))
    }

    func testFullPlayerIsTheSoleSourceWhilePresented() {
        XCTAssertTrue(source(.fullPlayer, tab: .library, presented: true))
        XCTAssertTrue(source(.fullPlayer, tab: .player, presented: true))
        XCTAssertFalse(source(.fullPlayer, tab: .library, presented: false))
        XCTAssertFalse(source(.fullPlayer, tab: .player, presented: false))

        XCTAssertFalse(source(.miniPlayer, tab: .library, presented: true))
        XCTAssertFalse(source(.playerTab, tab: .player, presented: true))
    }

    func testPlayerTabIsSourceOnlyWhenSelectedAndCollapsed() {
        XCTAssertTrue(source(.playerTab, tab: .player, presented: false))
        XCTAssertFalse(source(.playerTab, tab: .player, presented: true))
        XCTAssertFalse(source(.playerTab, tab: .library, presented: false))
        XCTAssertFalse(source(.playerTab, tab: .library, presented: true))
    }

    func testMiniStaysInGroupWhileFullPlayerPresents() {
        XCTAssertTrue(participates(.miniPlayer, tab: .library, presented: true))
        XCTAssertFalse(source(.miniPlayer, tab: .library, presented: true))
        XCTAssertTrue(source(.fullPlayer, tab: .library, presented: true))
    }

    func testInactivePlayerTabLeavesTheGroup() {
        XCTAssertFalse(participates(.playerTab, tab: .library, presented: false))
        XCTAssertFalse(participates(.playerTab, tab: .library, presented: true))
    }

    func testCoverAndPlayShareTheSameSourceGate() {
        XCTAssertEqual(PlayerChrome.coverMatchID, "nowPlayingCover")
        XCTAssertEqual(PlayerChrome.playMatchID, "nowPlayingPlay")
        for tab in [AppTab.library, .player] {
            for presented in [false, true] {
                let sources = NowPlayingMatchSurface.allCases.filter {
                    NowPlayingMatchedGeometry.isSource($0, selectedTab: tab, isFullPlayerPresented: presented)
                }
                XCTAssertLessThanOrEqual(sources.count, 1)
            }
        }
    }

    private func source(
        _ surface: NowPlayingMatchSurface,
        tab: AppTab,
        presented: Bool
    ) -> Bool {
        NowPlayingMatchedGeometry.isSource(surface, selectedTab: tab, isFullPlayerPresented: presented)
    }

    private func participates(
        _ surface: NowPlayingMatchSurface,
        tab: AppTab,
        presented: Bool
    ) -> Bool {
        NowPlayingMatchedGeometry.participates(surface, selectedTab: tab, isFullPlayerPresented: presented)
    }
}
