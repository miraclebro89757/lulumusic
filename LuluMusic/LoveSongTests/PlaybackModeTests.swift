import XCTest
@testable import LuluMusic

final class PlaybackModeTests: XCTestCase {
    func testCyclesThreeStatesOnly() {
        var nav = PlaybackNavigator(mode: .sequential)
        XCTAssertEqual(nav.mode, .sequential)
        nav.cycle()
        XCTAssertEqual(nav.mode, .repeatOne)
        nav.cycle()
        XCTAssertEqual(nav.mode, .shuffle)
        nav.cycle()
        XCTAssertEqual(nav.mode, .sequential)
        XCTAssertEqual(PlaybackMode.allCases.count, 3)
    }

    func testSequentialStopsAtEndOnAutoAdvance() {
        let nav = PlaybackNavigator(mode: .sequential)
        XCTAssertEqual(nav.actionOnTrackEnd(currentIndex: 0, count: 3), .advanceTo(1))
        XCTAssertEqual(nav.actionOnTrackEnd(currentIndex: 2, count: 3), .stop)
    }

    func testRepeatOneReplaysCurrentOnEnd() {
        let nav = PlaybackNavigator(mode: .repeatOne)
        XCTAssertEqual(nav.actionOnTrackEnd(currentIndex: 1, count: 4), .replayCurrent)
        XCTAssertEqual(nav.indexOnUserNext(currentIndex: 1, count: 4), 2)
    }

    func testShuffleWrapsOnEnd() {
        let nav = PlaybackNavigator(mode: .shuffle)
        XCTAssertEqual(nav.actionOnTrackEnd(currentIndex: 2, count: 3), .advanceTo(0))
    }

    func testPreviousRestartsAfterThreeSeconds() {
        let nav = PlaybackNavigator(mode: .sequential)
        XCTAssertEqual(
            nav.actionOnUserPrevious(currentIndex: 2, count: 5, positionMS: 3500),
            .seekToStart
        )
        XCTAssertEqual(
            nav.actionOnUserPrevious(currentIndex: 2, count: 5, positionMS: 800),
            .previousIndex(1)
        )
    }

    func testUserNextWraps() {
        let nav = PlaybackNavigator(mode: .sequential)
        XCTAssertEqual(nav.indexOnUserNext(currentIndex: 2, count: 3), 0)
    }
}
