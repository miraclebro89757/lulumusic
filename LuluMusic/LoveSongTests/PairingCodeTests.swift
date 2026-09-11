import XCTest
@testable import LuluMusic

final class PairingCodeTests: XCTestCase {
    func testGeneratedCodeIsFourDigits() {
        let code = PairingCode.generate(using: { 7 })
        XCTAssertEqual(code.digits, "7777")
        XCTAssertEqual(code.digits.count, 4)
        XCTAssertTrue(code.digits.allSatisfy(\.isNumber))
    }

    func testRejectsMalformedCodes() {
        XCTAssertNil(PairingCode(digits: "12"))
        XCTAssertNil(PairingCode(digits: "abcd"))
        XCTAssertNil(PairingCode(digits: "12345"))
        XCTAssertNil(PairingCode(digits: ""))
    }

    func testPairingRequiredBeforeUpload() {
        var auth = WiFiImportAuth(pairingCode: PairingCode(digits: "2048")!)
        XCTAssertFalse(auth.isAuthorized(sessionToken: nil))
        XCTAssertFalse(auth.isAuthorized(sessionToken: "random"))

        XCTAssertEqual(auth.pair(entered: "0000"), .failure(.mismatch))
        XCTAssertEqual(auth.pair(entered: "hi"), .failure(.malformedCode))
        XCTAssertFalse(auth.isAuthorized(sessionToken: nil))

        let token: String
        switch auth.pair(entered: "2048") {
        case .success(let value):
            token = value
        case .failure:
            return XCTFail("expected success")
        }
        XCTAssertTrue(auth.isAuthorized(sessionToken: token))
    }

    func testReusesStoredPairingCodeInsteadOfRegenerating() {
        let store = InMemoryPairingCodeStore()
        let first = PairingCodeStore.loadOrCreate(from: store, generate: { 2 })
        XCTAssertEqual(first.digits, "2222")
        let second = PairingCodeStore.loadOrCreate(from: store, generate: { 9 })
        XCTAssertEqual(second.digits, "2222")
        XCTAssertEqual(store.load()?.digits, "2222")
    }
}
