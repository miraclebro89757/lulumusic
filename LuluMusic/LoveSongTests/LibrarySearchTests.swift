import XCTest
@testable import LuluMusic

final class LibrarySearchTests: XCTestCase {
    private let tracks = [
        LibraryTrackInfo(title: "告白气球", artist: "周杰伦", venueTag: "鸟巢", duration: 215),
        LibraryTrackInfo(title: "海阔天空", artist: "Beyond", venueTag: "红磡", duration: 322),
        LibraryTrackInfo(title: "晴天", artist: "周杰伦", venueTag: "", duration: 269)
    ]

    func testSearchByTitleArtistAndVenueTag() {
        XCTAssertEqual(LibrarySearch.filtered(tracks, query: "周").map(\.title), ["告白气球", "晴天"])
        XCTAssertEqual(LibrarySearch.filtered(tracks, query: "鸟巢").map(\.title), ["告白气球"])
        XCTAssertEqual(LibrarySearch.filtered(tracks, query: "beyond").map(\.title), ["海阔天空"])
    }

    func testEmptyQueryReturnsAll() {
        XCTAssertEqual(LibrarySearch.filtered(tracks, query: "  ").count, 3)
    }

    func testColumnsExistOnProjection() {
        let row = tracks[0]
        XCTAssertFalse(row.title.isEmpty)
        XCTAssertFalse(row.artist.isEmpty)
        XCTAssertEqual(row.venueTag, "鸟巢")
        XCTAssertGreaterThan(row.duration, 0)
    }
}
