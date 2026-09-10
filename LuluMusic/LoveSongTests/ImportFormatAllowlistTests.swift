import XCTest
@testable import LuluMusic

final class ImportFormatAllowlistTests: XCTestCase {
    func testAllowsP0Formats() {
        for name in ["a.mp3", "b.M4A", "c.aac", "d.wav", "e.FLAC"] {
            XCTAssertTrue(ImportFormatAllowlist.isAllowed(fileName: name), name)
        }
    }

    func testRejectsOGGInV01() {
        XCTAssertTrue(ImportFormatAllowlist.isRejectedOGG(fileName: "live.ogg"))
        XCTAssertFalse(ImportFormatAllowlist.isAllowed(fileName: "live.ogg"))
        XCTAssertFalse(ImportFormatAllowlist.isAllowed(fileName: "x.oga"))
        XCTAssertFalse(ImportFormatAllowlist.isAllowed(url: URL(fileURLWithPath: "/tmp/song.ogg")))
    }

    func testRejectsUnknown() {
        XCTAssertFalse(ImportFormatAllowlist.isAllowed(fileName: "notes.txt"))
        XCTAssertFalse(ImportFormatAllowlist.isAllowed(fileName: "clip.mp4"))
    }
}
