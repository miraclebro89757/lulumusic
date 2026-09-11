import XCTest
@testable import LuluMusic

final class DanmakuStoreAndSchedulerTests: XCTestCase {
    func testStoreKeyedByTrackIdAndTimestamp() {
        let store = InMemoryDanmakuStore()
        let trackA = UUID()
        let trackB = UUID()
        store.insert(DanmakuRecord(trackId: trackA, timestampMS: 2000, text: "后"))
        store.insert(DanmakuRecord(trackId: trackA, timestampMS: 500, text: "先"))
        store.insert(DanmakuRecord(trackId: trackB, timestampMS: 500, text: "别的歌"))

        let a = store.records(for: trackA)
        XCTAssertEqual(a.map(\.text), ["先", "后"])
        XCTAssertEqual(store.records(for: trackB).count, 1)
    }

    func testReplaySpawnsLeadAndStaysWithin300ms() {
        let scheduler = DanmakuScheduler()
        let record = DanmakuRecord(trackId: UUID(), timestampMS: 10_000, text: "好听到哭")
        XCTAssertEqual(scheduler.replaySpawnTimeMS(for: record), 9_500)
        XCTAssertFalse(scheduler.shouldSpawnReplay(record: record, currentTimeMS: 9_400, alreadySpawned: []))
        XCTAssertTrue(scheduler.shouldSpawnReplay(record: record, currentTimeMS: 9_500, alreadySpawned: []))

        let display = scheduler.expectedDisplayTimeMS(for: record)
        XCTAssertTrue(scheduler.isWithinTimingTolerance(displayTimeMS: display, record: record))
        XCTAssertLessThanOrEqual(abs(display - record.timestampMS), 300)
    }

    func testSendEnqueuesImmediatelyWithin100msBudget() {
        let store = InMemoryDanmakuStore()
        var runtime = DanmakuRuntime(store: store)
        let track = UUID()
        let start = Date()
        let record = runtime.send(trackId: track, text: "安可", currentTimeMS: 1_200)
        let elapsedMS = Date().timeIntervalSince(start) * 1000
        XCTAssertNotNil(record)
        XCTAssertEqual(runtime.flying.count, 1)
        XCTAssertEqual(runtime.flying.first?.record.text, "安可")
        XCTAssertTrue(runtime.flying.first?.isLiveSend == true)
        XCTAssertLessThanOrEqual(elapsedMS, Double(runtime.scheduler.sendAppearBudgetMS) + 50)
        XCTAssertEqual(record?.timestampMS, 1_200)
    }

    func testOptimisticSendFliesBeforeSlowPersist() {
        let store = SlowDanmakuStore(delayMS: 180)
        var runtime = DanmakuRuntime(store: store)
        let track = UUID()
        let playerMS = PlaybackClock.milliseconds(fromPlayerSeconds: 3.25)
        let start = Date()
        let record = runtime.send(trackId: track, text: "立刻飞", currentTimeMS: playerMS)
        let elapsedMS = Date().timeIntervalSince(start) * 1000
        XCTAssertEqual(record?.timestampMS, 3_250)
        XCTAssertEqual(runtime.flying.first?.record.text, "立刻飞")
        XCTAssertLessThanOrEqual(elapsedMS, Double(runtime.scheduler.sendAppearBudgetMS))
        XCTAssertTrue(store.inserted.isEmpty, "persist must stay off the send path")
        runtime.persist(record!)
        XCTAssertEqual(store.inserted.map(\.text), ["立刻飞"])
    }

    func testReplayTickSpawnsSameTextAtSameTime() {
        let store = InMemoryDanmakuStore()
        let track = UUID()
        store.insert(DanmakuRecord(trackId: track, timestampMS: 8_000, text: "现场太顶了"))
        var runtime = DanmakuRuntime(store: store)
        runtime.tick(trackId: track, currentTimeMS: 7_400)
        XCTAssertTrue(runtime.flying.isEmpty)
        runtime.tick(trackId: track, currentTimeMS: 7_500)
        XCTAssertEqual(runtime.flying.map(\.record.text), ["现场太顶了"])
        let display = runtime.scheduler.expectedDisplayTimeMS(for: runtime.flying[0].record)
        XCTAssertLessThanOrEqual(abs(display - 8_000), 300)
    }

    func testLanesAndDensityCapFadeOldest() {
        let store = InMemoryDanmakuStore()
        var runtime = DanmakuRuntime(store: store)
        runtime.scheduler.densityCap = 5
        runtime.scheduler.maxLanes = 3
        let track = UUID()
        for i in 0..<7 {
            _ = runtime.send(trackId: track, text: "弹幕\(i)", currentTimeMS: i * 100)
        }
        XCTAssertEqual(runtime.flying.count, 7)
        XCTAssertEqual(runtime.flying.filter(\.fading).count, 2)
        XCTAssertEqual(runtime.flying.filter { !$0.fading }.count, 5)
        let lanes = Set(runtime.flying.map(\.lane))
        XCTAssertTrue(lanes.isSubset(of: Set(0...2)))
        XCTAssertLessThanOrEqual(lanes.count, 3)
    }

    func testEmptySendIgnored() {
        var runtime = DanmakuRuntime(store: InMemoryDanmakuStore())
        XCTAssertNil(runtime.send(trackId: UUID(), text: "   ", currentTimeMS: 0))
        XCTAssertTrue(runtime.flying.isEmpty)
    }
}

private final class SlowDanmakuStore: DanmakuStoring {
    var delayMS: UInt32
    var inserted: [DanmakuRecord] = []

    init(delayMS: UInt32) {
        self.delayMS = delayMS
    }

    func insert(_ record: DanmakuRecord) {
        usleep(delayMS * 1_000)
        inserted.append(record)
    }

    func records(for trackId: UUID) -> [DanmakuRecord] {
        inserted.filter { $0.trackId == trackId }
    }
}
