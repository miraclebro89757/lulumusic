import Foundation

enum AudioSessionCategoryKind: String, Equatable {
    case playback
}

enum PlayerItemReadiness: Equatable {
    case unknown
    case readyToPlay
    case failed

    init(statusRawValue: Int) {
        switch statusRawValue {
        case 1: self = .readyToPlay
        case 2: self = .failed
        default: self = .unknown
        }
    }
}

enum TimeControlKind: Equatable {
    case paused
    case waiting
    case playing

    init(statusRawValue: Int) {
        switch statusRawValue {
        case 2: self = .playing
        case 1: self = .waiting
        default: self = .paused
        }
    }
}

enum TransportPlayAction: Equatable {
    case togglePlayPause
    case playLibraryFromStart
    case none
}

/// Testable play hook: session + AVPlayer output that must hold before audible start.
struct AudiblePlayIntent: Equatable {
    var activatePlaybackSession: Bool
    var sessionCategory: AudioSessionCategoryKind
    var setSessionActive: Bool
    var unmute: Bool
    var volume: Float
    var rate: Float
    var callAVPlayerPlay: Bool
    var playImmediately: Bool
    var retryWhenReadyToPlay: Bool
    var waitToMinimizeStalling: Bool
}

enum AudiblePlayback {
    static func playIntent(
        hasCurrentTrack: Bool,
        fileExists: Bool,
        itemReadiness: PlayerItemReadiness
    ) -> AudiblePlayIntent? {
        guard hasCurrentTrack, fileExists, itemReadiness != .failed else { return nil }
        let ready = itemReadiness == .readyToPlay
        return AudiblePlayIntent(
            activatePlaybackSession: true,
            sessionCategory: .playback,
            setSessionActive: true,
            unmute: true,
            volume: 1,
            rate: 1,
            callAVPlayerPlay: true,
            playImmediately: ready,
            retryWhenReadyToPlay: !ready,
            waitToMinimizeStalling: false
        )
    }

    static func uiIsPlaying(timeControl: TimeControlKind) -> Bool {
        timeControl != .paused
    }

    static func uiIsPlaying(optimisticIsPlaying: Bool, timeControl: TimeControlKind) -> Bool {
        _ = optimisticIsPlaying
        return uiIsPlaying(timeControl: timeControl)
    }

    static func transportAction(hasCurrentTrack: Bool, libraryIsEmpty: Bool) -> TransportPlayAction {
        if hasCurrentTrack { return .togglePlayPause }
        if !libraryIsEmpty { return .playLibraryFromStart }
        return .none
    }
}
