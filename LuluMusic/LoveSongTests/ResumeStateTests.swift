import XCTest
@testable import LuluMusic

final class ResumeStateTests: XCTestCase {
    func testPersistsTrackPositionModeAndDanmaku() {
        let store = InMemoryResumeStore()
        let id = UUID()
        let state = PlaybackResumeState(trackID: id, positionMS: 123_456, danmakuEnabled: false, mode: .repeatOne)
        store.save(state)
        let loaded = store.load()
        XCTAssertEqual(loaded.trackID, id)
        XCTAssertEqual(loaded.positionMS, 123_456)
        XCTAssertEqual(loaded.danmakuEnabled, false)
        XCTAssertEqual(loaded.mode, .repeatOne)
        XCTAssertEqual(loaded.positionSeconds, 123.456, accuracy: 0.001)
    }

    func testEmptyResumeWhenNothingSaved() {
        XCTAssertEqual(InMemoryResumeStore().load(), .empty)
    }

    func testPositionMSConversion() {
        XCTAssertEqual(PlaybackResumeState.positionMS(from: 1.5), 1500)
        XCTAssertEqual(PlaybackResumeState.positionMS(from: -1), 0)
    }
}
