import Foundation

/// F10: three playback modes only — sequential / repeat-one / shuffle.
enum PlaybackMode: String, CaseIterable, Codable, Equatable {
    case sequential
    case repeatOne
    case shuffle

    var next: PlaybackMode {
        switch self {
        case .sequential: return .repeatOne
        case .repeatOne: return .shuffle
        case .shuffle: return .sequential
        }
    }

    var title: String {
        switch self {
        case .sequential: return L10n.sequential
        case .repeatOne: return L10n.repeatOne
        case .shuffle: return L10n.shuffle
        }
    }

    var systemImage: String {
        switch self {
        case .sequential: return "repeat"
        case .repeatOne: return "repeat.1"
        case .shuffle: return "shuffle"
        }
    }
}

enum TrackEndAction: Equatable {
    case replayCurrent
    case advanceTo(Int)
    case stop
}

enum PreviousAction: Equatable {
    case seekToStart
    case previousIndex(Int)
}

struct PlaybackNavigator: Equatable {
    var mode: PlaybackMode

    init(mode: PlaybackMode = .sequential) {
        self.mode = mode
    }

    mutating func cycle() {
        mode = mode.next
    }

    /// Auto-advance when a track finishes.
    func actionOnTrackEnd(currentIndex: Int, count: Int) -> TrackEndAction {
        guard count > 0, currentIndex >= 0, currentIndex < count else { return .stop }
        switch mode {
        case .repeatOne:
            return .replayCurrent
        case .sequential:
            if currentIndex + 1 < count { return .advanceTo(currentIndex + 1) }
            return .stop
        case .shuffle:
            if currentIndex + 1 < count { return .advanceTo(currentIndex + 1) }
            return .advanceTo(0)
        }
    }

    /// User / remote next. Always advances; wraps to 0 at the end.
    func indexOnUserNext(currentIndex: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        if currentIndex + 1 < count { return currentIndex + 1 }
        return 0
    }

    /// Previous: restart if > 3s into the track, else go back (wrap in shuffle).
    func actionOnUserPrevious(currentIndex: Int, count: Int, positionMS: Int, restartThresholdMS: Int = 3000) -> PreviousAction {
        if positionMS > restartThresholdMS { return .seekToStart }
        guard count > 0 else { return .seekToStart }
        if currentIndex > 0 { return .previousIndex(currentIndex - 1) }
        if mode == .shuffle || mode == .sequential {
            return .previousIndex(count - 1)
        }
        return .seekToStart
    }

    static func shuffledOrder<T>(of items: [T], pinning index: Int) -> [T] {
        guard items.indices.contains(index) else { return items.shuffled() }
        var rest = items.enumerated().filter { $0.offset != index }.map(\.element).shuffled()
        rest.insert(items[index], at: 0)
        return rest
    }
}
