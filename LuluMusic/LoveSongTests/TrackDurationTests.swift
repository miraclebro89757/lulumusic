import AVFoundation
import XCTest
@testable import LuluMusic

final class TrackDurationTests: XCTestCase {
    func testKeepsOrdinarySongLengthsAsSeconds() {
        XCTAssertEqual(TrackDuration.playbackSeconds(fromRaw: 0), 0, accuracy: 0.0001)
        XCTAssertEqual(TrackDuration.playbackSeconds(fromRaw: 215), 215, accuracy: 0.0001)
        XCTAssertEqual(TrackDuration.playbackSeconds(fromRaw: 215.4), 215.4, accuracy: 0.0001)
        XCTAssertEqual(TrackDuration.playbackSeconds(fromRaw: 3 * 3600), 3 * 3600, accuracy: 0.0001)
    }

    func testTreatsImplausibleHourLongValuesAsMilliseconds() {
        XCTAssertEqual(TrackDuration.playbackSeconds(fromRaw: 215_000), 215, accuracy: 0.0001)
        XCTAssertEqual(TrackDuration.playbackSeconds(fromRaw: 30_000), 30, accuracy: 0.0001)
        XCTAssertEqual(TrackDuration.playbackSeconds(fromRaw: 1_200_000), 1_200, accuracy: 0.0001)
    }

    func testRejectsInvalidDurations() {
        XCTAssertEqual(TrackDuration.playbackSeconds(fromRaw: -8), 0, accuracy: 0.0001)
        XCTAssertEqual(TrackDuration.playbackSeconds(fromRaw: .infinity), 0, accuracy: 0.0001)
        XCTAssertEqual(TrackDuration.playbackSeconds(fromRaw: .nan), 0, accuracy: 0.0001)
    }

    func testCMTimeSecondsStaySeconds() {
        let cm = CMTime(seconds: 269.2, preferredTimescale: 600)
        XCTAssertEqual(TrackDuration.playbackSeconds(from: cm), 269.2, accuracy: 0.01)
    }

    func testCMTimeMillisecondTicksWithTimescaleOne() {
        let cm = CMTime(value: 215_000, timescale: 1)
        XCTAssertEqual(TrackDuration.playbackSeconds(from: cm), 215, accuracy: 0.01)
    }

    func testInvalidCMTimeIsZero() {
        XCTAssertEqual(TrackDuration.playbackSeconds(from: .invalid), 0, accuracy: 0.0001)
        XCTAssertEqual(TrackDuration.playbackSeconds(from: .indefinite), 0, accuracy: 0.0001)
    }

    func testDisplayFormatsSecondsNotMillisecondTicks() {
        XCTAssertEqual(TimeFormat.duration(0), "0:00")
        XCTAssertEqual(TimeFormat.duration(215), "3:35")
        XCTAssertEqual(TimeFormat.duration(215_000), "3:35")
        XCTAssertEqual(TimeFormat.duration(3_661), "1:01:01")
        XCTAssertEqual(TimeFormat.duration(-1), L10n.durationUnknown)
        XCTAssertEqual(TimeFormat.duration(.infinity), L10n.durationUnknown)
    }

    func testResolvedPlaybackSecondsKeepsKnownRawWithoutReadingFile() async {
        let missing = URL(fileURLWithPath: "/tmp/lulumusic-missing-\(UUID().uuidString).m4a")
        let seconds = await TrackDuration.resolvedPlaybackSeconds(raw: 215, fileURL: missing)
        XCTAssertEqual(seconds, 215, accuracy: 0.0001)
    }

    func testResolvedPlaybackSecondsNormalizesMillisecondRaw() async {
        let missing = URL(fileURLWithPath: "/tmp/lulumusic-missing-\(UUID().uuidString).m4a")
        let seconds = await TrackDuration.resolvedPlaybackSeconds(raw: 215_000, fileURL: missing)
        XCTAssertEqual(seconds, 215, accuracy: 0.0001)
    }

    func testResolvedPlaybackSecondsReturnsZeroWhenRawUnknownAndAssetMissing() async {
        let missing = URL(fileURLWithPath: "/tmp/lulumusic-missing-\(UUID().uuidString).m4a")
        let seconds = await TrackDuration.resolvedPlaybackSeconds(raw: 0, fileURL: missing)
        XCTAssertEqual(seconds, 0, accuracy: 0.0001)
    }
}
