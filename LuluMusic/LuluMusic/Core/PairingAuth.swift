import Foundation

/// 4-digit pairing used on first Wi‑Fi web connect (F02).
struct PairingCode: Equatable, Hashable {
    let digits: String

    init?(digits: String) {
        let trimmed = digits.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count == 4, trimmed.allSatisfy({ $0.isNumber }) else { return nil }
        self.digits = trimmed
    }

    static func generate(using rng: () -> Int = { Int.random(in: 0...9) }) -> PairingCode {
        let value = (0..<4).map { _ in String(rng() % 10) }.joined()
        return PairingCode(digits: value)!
    }

    func matches(_ entered: String) -> Bool {
        PairingCode(digits: entered)?.digits == digits
    }
}

enum PairingAuthError: Error, Equatable {
    case malformedCode
    case mismatch
    case missingSession
}

/// Session tokens issued after a correct pairing code. Uploads require a token.
struct WiFiImportAuth: Equatable {
    var pairingCode: PairingCode
    private(set) var sessions: Set<String>

    init(pairingCode: PairingCode, sessions: Set<String> = []) {
        self.pairingCode = pairingCode
        self.sessions = sessions
    }

    mutating func pair(entered: String) -> Result<String, PairingAuthError> {
        guard PairingCode(digits: entered) != nil else { return .failure(.malformedCode) }
        guard pairingCode.matches(entered) else { return .failure(.mismatch) }
        let token = UUID().uuidString
        sessions.insert(token)
        return .success(token)
    }

    func isAuthorized(sessionToken: String?) -> Bool {
        guard let sessionToken, !sessionToken.isEmpty else { return false }
        return sessions.contains(sessionToken)
    }
}

protocol PairingCodeStoring: AnyObject {
    func load() -> PairingCode?
    func save(_ code: PairingCode)
}

final class InMemoryPairingCodeStore: PairingCodeStoring {
    private var code: PairingCode?

    func load() -> PairingCode? { code }

    func save(_ code: PairingCode) { self.code = code }
}

final class UserDefaultsPairingCodeStore: PairingCodeStoring {
    static let key = "lovesong.wifi.pairing.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> PairingCode? {
        guard let digits = defaults.string(forKey: Self.key) else { return nil }
        return PairingCode(digits: digits)
    }

    func save(_ code: PairingCode) {
        defaults.set(code.digits, forKey: Self.key)
    }
}

enum PairingCodeStore {
    static func loadOrCreate(
        from store: PairingCodeStoring,
        generate: @escaping () -> Int = { Int.random(in: 0...9) }
    ) -> PairingCode {
        if let existing = store.load() { return existing }
        let code = PairingCode.generate(using: generate)
        store.save(code)
        return code
    }
}
