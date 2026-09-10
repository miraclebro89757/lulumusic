import Foundation

enum RepeatMode: Int, CaseIterable, Codable {
    case off
    case all
    case one

    var next: RepeatMode {
        switch self {
        case .off: return .all
        case .all: return .one
        case .one: return .off
        }
    }

    var title: String {
        switch self {
        case .off: return L10n.repeatOff
        case .all: return L10n.repeatAll
        case .one: return L10n.repeatOne
        }
    }

    var systemImage: String {
        switch self {
        case .off: return "repeat"
        case .all: return "repeat"
        case .one: return "repeat.1"
        }
    }
}
