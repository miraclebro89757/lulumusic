import XCTest
@testable import LuluMusic

final class LiveDanmakuWindowTests: XCTestCase {
    func testIncludesOnlyCommentsAtOrBeforeNow() {
        let track = UUID()
        let records = [
            DanmakuRecord(trackId: track, timestampMS: 1_000, text: "early"),
            DanmakuRecord(trackId: track, timestampMS: 5_000, text: "now"),
            DanmakuRecord(trackId: track, timestampMS: 9_000, text: "future")
        ]
        let visible = LiveDanmakuWindow.visible(records: records, nowMS: 5_000)
        XCTAssertEqual(visible.map(\.text), ["early", "now"])
    }

    func testCapsVisibleSetAtFiftyMostRecentTriggered() {
        let track = UUID()
        let records = (0..<80).map { index in
            DanmakuRecord(trackId: track, timestampMS: index * 100, text: "c\(index)")
        }
        let visible = LiveDanmakuWindow.visible(records: records, nowMS: 10_000)
        XCTAssertEqual(visible.count, LiveDanmakuWindow.maxVisible)
        XCTAssertEqual(visible.first?.text, "c30")
        XCTAssertEqual(visible.last?.text, "c79")
    }

    func testSeekBackwardRebuildsWindowFromScratch() {
        let track = UUID()
        let records = (0..<10).map { index in
            DanmakuRecord(trackId: track, timestampMS: index * 1_000, text: "t\(index)")
        }
        let atNine = LiveDanmakuWindow.visible(records: records, nowMS: 9_000)
        XCTAssertEqual(atNine.map(\.text), (0...9).map { "t\($0)" })

        let afterSeek = LiveDanmakuWindow.visible(records: records, nowMS: 2_000)
        XCTAssertEqual(afterSeek.map(\.text), ["t0", "t1", "t2"])
    }

    func testStableOrderByTimestampThenCreatedAt() {
        let track = UUID()
        let earlier = Date(timeIntervalSince1970: 100)
        let later = Date(timeIntervalSince1970: 200)
        let records = [
            DanmakuRecord(trackId: track, timestampMS: 1_000, text: "second", createdAt: later),
            DanmakuRecord(trackId: track, timestampMS: 1_000, text: "first", createdAt: earlier),
            DanmakuRecord(trackId: track, timestampMS: 500, text: "zero", createdAt: later)
        ]
        let visible = LiveDanmakuWindow.visible(records: records, nowMS: 1_000)
        XCTAssertEqual(visible.map(\.text), ["zero", "first", "second"])
    }
}
