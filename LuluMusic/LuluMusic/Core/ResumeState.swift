import Foundation

/// Persisted session (F09): current track, position, danmaku toggle, mode.
struct PlaybackResumeState: Codable, Equatable {
    var trackID: UUID?
    var positionMS: Int
    var danmakuEnabled: Bool
    var mode: PlaybackMode

    static let empty = PlaybackResumeState(trackID: nil, positionMS: 0, danmakuEnabled: true, mode: .sequential)

    var positionSeconds: TimeInterval {
        TimeInterval(positionMS) / 1000.0
    }

    static func positionMS(from seconds: TimeInterval) -> Int {
        guard seconds.isFinite, seconds > 0 else { return 0 }
        return Int((seconds * 1000).rounded())
    }
}

protocol ResumeStoring: AnyObject {
    func save(_ state: PlaybackResumeState)
    func load() -> PlaybackResumeState
}

final class InMemoryResumeStore: ResumeStoring {
    private var state: PlaybackResumeState = .empty

    func save(_ state: PlaybackResumeState) {
        self.state = state
    }

    func load() -> PlaybackResumeState {
        state
    }
}

final class UserDefaultsResumeStore: ResumeStoring {
    static let key = "lovesong.playback.resume.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save(_ state: PlaybackResumeState) {
        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: Self.key)
        }
    }

    func load() -> PlaybackResumeState {
        guard let data = defaults.data(forKey: Self.key),
              let state = try? JSONDecoder().decode(PlaybackResumeState.self, from: data) else {
            return .empty
        }
        return state
    }
}
