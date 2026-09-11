import XCTest
@testable import LuluMusic

final class ScrubSeekTests: XCTestCase {
    func testMapsBarFractionOntoDurationSeconds() {
        XCTAssertEqual(ScrubSeek.time(x: 0, width: 200, duration: 180), 0, accuracy: 0.001)
        XCTAssertEqual(ScrubSeek.time(x: 100, width: 200, duration: 180), 90, accuracy: 0.001)
        XCTAssertEqual(ScrubSeek.time(x: 200, width: 200, duration: 180), 180, accuracy: 0.001)
        XCTAssertEqual(ScrubSeek.time(x: 50, width: 100, duration: 215.4), 107.7, accuracy: 0.001)
    }

    func testClampsOffBarDrags() {
        XCTAssertEqual(ScrubSeek.time(x: -40, width: 100, duration: 180), 0, accuracy: 0.001)
        XCTAssertEqual(ScrubSeek.time(x: 140, width: 100, duration: 180), 180, accuracy: 0.001)
    }

    func testZeroDurationDoesNotInventATenthSecondSpan() {
        XCTAssertEqual(ScrubSeek.time(x: 80, width: 100, duration: 0), 0, accuracy: 0.001)
        XCTAssertEqual(ScrubSeek.time(x: 80, width: 100, duration: .nan), 0, accuracy: 0.001)
    }

    func testDoesNotTreatNormalizedFractionAsMilliseconds() {
        let time = ScrubSeek.time(x: 0.5, width: 1, duration: 180)
        XCTAssertEqual(time, 90, accuracy: 0.001)
        XCTAssertNotEqual(time, 90_000, accuracy: 1)
    }

    func testSeekCommandUsesPlayerSeconds() {
        let command = ScrubSeek.command(x: 25, width: 100, duration: 200)
        XCTAssertEqual(command.seconds, 50, accuracy: 0.001)
        XCTAssertTrue(command.shouldSeek)
        XCTAssertFalse(ScrubSeek.command(x: 25, width: 100, duration: 0).shouldSeek)
    }
}
