import XCTest
@testable import LuluMusic

final class PlaybackClockTests: XCTestCase {
    func testMillisecondsComeFromPlayerSecondsNotWallClock() {
        XCTAssertEqual(PlaybackClock.milliseconds(fromPlayerSeconds: 0), 0)
        XCTAssertEqual(PlaybackClock.milliseconds(fromPlayerSeconds: 1.5), 1_500)
        XCTAssertEqual(PlaybackClock.milliseconds(fromPlayerSeconds: 12.3456), 12_346)
        XCTAssertEqual(PlaybackClock.milliseconds(fromPlayerSeconds: -0.4), 0)
        XCTAssertEqual(PlaybackClock.milliseconds(fromPlayerSeconds: .infinity), 0)
        XCTAssertEqual(PlaybackClock.milliseconds(fromPlayerSeconds: .nan), 0)
        XCTAssertEqual(PlaybackClock.source, .avPlayerCurrentTime)
        XCTAssertNotEqual(PlaybackClock.source, .systemDate)
    }

    func testDisplayAndDanmakuShareTheSamePlayerDerivedMS() {
        let playerSeconds: TimeInterval = 83.201
        let displayMS = PlaybackClock.milliseconds(fromPlayerSeconds: playerSeconds)
        let danmakuMS = PlaybackClock.milliseconds(fromPlayerSeconds: playerSeconds)
        XCTAssertEqual(displayMS, danmakuMS)
        XCTAssertEqual(displayMS, 83_201)
    }
}
