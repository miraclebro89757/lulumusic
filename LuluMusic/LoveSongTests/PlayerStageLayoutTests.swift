import XCTest
@testable import LuluMusic

final class PlayerStageLayoutTests: XCTestCase {
    func testCoverStackContainsRearPeekSoItCannotOverlapHeader() {
        let side: CGFloat = 304
        let frames = PlayerStageLayout.coverFrames(side: side)
        XCTAssertGreaterThanOrEqual(frames.rear.minY, frames.stack.minY)
        XCTAssertGreaterThanOrEqual(frames.main.minY, frames.rear.minY)
        XCTAssertEqual(PlayerStageLayout.rearOverflowAboveStack(side: side), 0, accuracy: 0.001)
        XCTAssertGreaterThanOrEqual(PlayerStageLayout.headerCoverClearance(side: side), 12)
    }

    func testHeaderToCoverSpacingMatchesPixelSpec() {
        XCTAssertGreaterThanOrEqual(PlayerStageLayout.headerToCoverSpacing, 12)
        XCTAssertLessThanOrEqual(PlayerStageLayout.headerToCoverSpacing, 16)
        XCTAssertGreaterThanOrEqual(PlayerStageLayout.headerMinHeight, 44)
        XCTAssertLessThanOrEqual(PlayerStageLayout.headerMinHeight, 48)
    }

    func testRearCardPeeksUpAndRightInsideStack() {
        let side: CGFloat = 280
        let frames = PlayerStageLayout.coverFrames(side: side)
        XCTAssertEqual(frames.main.minY - frames.rear.minY, PlayerStageLayout.rearPeekY, accuracy: 0.001)
        XCTAssertEqual(frames.rear.minX - frames.main.minX, PlayerStageLayout.rearPeekX, accuracy: 0.001)
        XCTAssertLessThanOrEqual(frames.main.maxY, frames.stack.maxY)
        XCTAssertEqual(frames.stack.height, side + PlayerStageLayout.rearPeekY, accuracy: 0.001)
        XCTAssertEqual(frames.stack.width, side + PlayerStageLayout.rearPeekX, accuracy: 0.001)
    }

    func testCoverSideCapsAtThemeMax() {
        XCTAssertEqual(
            PlayerStageLayout.coverSide(containerWidth: 390, maxSide: 304),
            min(304, 390 * 0.76),
            accuracy: 0.001
        )
        XCTAssertEqual(
            PlayerStageLayout.coverSide(containerWidth: 500, maxSide: 304),
            304,
            accuracy: 0.001
        )
    }

    func testLegacyCenteredOffsetWouldOverflowHeaderGap() {
        let side: CGFloat = 304
        let frameHeight = side + 10
        let rearHeight = side + 4
        let centeredOffsetY: CGFloat = -10
        let rearTop = (frameHeight - rearHeight) / 2 + centeredOffsetY
        XCTAssertLessThan(rearTop, 0)
        XCTAssertGreaterThan(PlayerStageLayout.headerToCoverSpacing + rearTop, 0)
        XCTAssertEqual(PlayerStageLayout.rearOverflowAboveStack(side: side), 0, accuracy: 0.001)
    }
}
