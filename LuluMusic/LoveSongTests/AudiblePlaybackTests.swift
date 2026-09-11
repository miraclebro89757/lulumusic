import XCTest
@testable import LuluMusic

final class AudiblePlaybackTests: XCTestCase {
    func testPlayIntentActivatesPlaybackSessionAndCallsAVPlayerPlay() {
        let intent = AudiblePlayback.playIntent(
            hasCurrentTrack: true,
            fileExists: true,
            itemReadiness: .readyToPlay
        )
        XCTAssertNotNil(intent)
        XCTAssertEqual(intent?.activatePlaybackSession, true)
        XCTAssertEqual(intent?.sessionCategory, .playback)
        XCTAssertEqual(intent?.setSessionActive, true)
        XCTAssertEqual(intent?.callAVPlayerPlay, true)
        XCTAssertEqual(intent?.playImmediately, true)
        XCTAssertEqual(intent?.unmute, true)
        XCTAssertEqual(intent?.volume, 1)
        XCTAssertEqual(intent?.rate, 1)
        XCTAssertEqual(intent?.waitToMinimizeStalling, false)
        XCTAssertEqual(intent?.retryWhenReadyToPlay, false)
    }

    func testPlayIntentRetriesWhenItemNotYetReadyToPlay() {
        let intent = AudiblePlayback.playIntent(
            hasCurrentTrack: true,
            fileExists: true,
            itemReadiness: .unknown
        )
        XCTAssertEqual(intent?.callAVPlayerPlay, true)
        XCTAssertEqual(intent?.playImmediately, false)
        XCTAssertEqual(intent?.retryWhenReadyToPlay, true)
        XCTAssertEqual(intent?.activatePlaybackSession, true)
        XCTAssertEqual(intent?.sessionCategory, .playback)
    }

    func testPlayIntentNilWhenFileMissingOrItemFailed() {
        XCTAssertNil(
            AudiblePlayback.playIntent(
                hasCurrentTrack: true,
                fileExists: false,
                itemReadiness: .readyToPlay
            )
        )
        XCTAssertNil(
            AudiblePlayback.playIntent(
                hasCurrentTrack: true,
                fileExists: true,
                itemReadiness: .failed
            )
        )
        XCTAssertNil(
            AudiblePlayback.playIntent(
                hasCurrentTrack: false,
                fileExists: true,
                itemReadiness: .readyToPlay
            )
        )
    }

    func testUIPlayingFollowsTimeControlNotOptimisticFlag() {
        XCTAssertTrue(AudiblePlayback.uiIsPlaying(timeControl: .playing))
        XCTAssertTrue(AudiblePlayback.uiIsPlaying(timeControl: .waiting))
        XCTAssertFalse(AudiblePlayback.uiIsPlaying(timeControl: .paused))
        XCTAssertFalse(AudiblePlayback.uiIsPlaying(optimisticIsPlaying: true, timeControl: .paused))
        XCTAssertTrue(AudiblePlayback.uiIsPlaying(optimisticIsPlaying: false, timeControl: .playing))
    }

    func testTransportPlayStartsLibraryWhenNoCurrentTrack() {
        XCTAssertEqual(
            AudiblePlayback.transportAction(hasCurrentTrack: true, libraryIsEmpty: false),
            .togglePlayPause
        )
        XCTAssertEqual(
            AudiblePlayback.transportAction(hasCurrentTrack: false, libraryIsEmpty: false),
            .playLibraryFromStart
        )
        XCTAssertEqual(
            AudiblePlayback.transportAction(hasCurrentTrack: false, libraryIsEmpty: true),
            .none
        )
    }

    func testItemReadinessFromAVPlayerItemStatusRawValues() {
        XCTAssertEqual(PlayerItemReadiness(statusRawValue: 0), .unknown)
        XCTAssertEqual(PlayerItemReadiness(statusRawValue: 1), .readyToPlay)
        XCTAssertEqual(PlayerItemReadiness(statusRawValue: 2), .failed)
        XCTAssertEqual(TimeControlKind(statusRawValue: 0), .paused)
        XCTAssertEqual(TimeControlKind(statusRawValue: 1), .waiting)
        XCTAssertEqual(TimeControlKind(statusRawValue: 2), .playing)
    }
}
