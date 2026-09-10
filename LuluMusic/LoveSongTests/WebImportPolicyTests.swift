import XCTest
@testable import LuluMusic

final class WebImportPolicyTests: XCTestCase {
    func testAdvertisesHttpIPPortOnLANOnly() {
        XCTAssertEqual(
            LANBindPolicy.advertisedURL(ips: ["127.0.0.1", "192.168.1.23"], port: 8787),
            "http://192.168.1.23:8787"
        )
        XCTAssertNil(LANBindPolicy.advertisedURL(ips: ["127.0.0.1"], port: 80))
        XCTAssertTrue(LANBindPolicy.isAdvertisableLAN("10.0.0.8"))
        XCTAssertTrue(LANBindPolicy.isAdvertisableLAN("172.16.0.2"))
        XCTAssertFalse(LANBindPolicy.isAdvertisableLAN("8.8.8.8"))
        XCTAssertFalse(LANBindPolicy.shouldBindInterface("pdp_ip0"))
        XCTAssertTrue(LANBindPolicy.shouldBindInterface("en0"))
    }

    func testServerOnlyWhileImportPageForeground() {
        XCTAssertTrue(WebImportLifecycle.shouldServe(pageVisible: true, phase: .foregroundActive))
        XCTAssertFalse(WebImportLifecycle.shouldServe(pageVisible: false, phase: .foregroundActive))
        XCTAssertFalse(WebImportLifecycle.shouldServe(pageVisible: true, phase: .background))
        XCTAssertFalse(WebImportLifecycle.shouldServe(pageVisible: true, phase: .locked))
        XCTAssertFalse(WebImportLifecycle.shouldServe(pageVisible: true, phase: .inactive))
    }

    func testUploadRequiresAuthAndDeleteIsRejected() {
        XCTAssertFalse(WebImportRouter.allowsDeleteFromWeb)
        XCTAssertEqual(WebImportRouter.route(method: "DELETE", path: "/upload", authorized: true), .rejectedDelete)
        XCTAssertEqual(WebImportRouter.route(method: "POST", path: "/upload", authorized: false), .unauthorized)
        XCTAssertEqual(WebImportRouter.route(method: "POST", path: "/upload", authorized: true), .upload)
        XCTAssertEqual(WebImportRouter.route(method: "POST", path: "/pair", authorized: false), .pair)
        XCTAssertEqual(WebImportRouter.route(method: "GET", path: "/", authorized: false), .page)
    }
}

final class IncomingTransferTests: XCTestCase {
    func testMultiSelectAndAirDropAllowlist() {
        XCTAssertTrue(IncomingTransfer.supportsMultipleSelection)
        let urls = [
            URL(fileURLWithPath: "/tmp/a.mp3"),
            URL(fileURLWithPath: "/tmp/b.ogg"),
            URL(fileURLWithPath: "/tmp/c.flac")
        ]
        let accepted = IncomingTransfer.importableURLs(from: urls)
        XCTAssertEqual(accepted.map(\.lastPathComponent), ["a.mp3", "c.flac"])
    }
}
