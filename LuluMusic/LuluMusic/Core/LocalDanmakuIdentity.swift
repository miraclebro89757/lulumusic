import Foundation

/// A08: bubble chrome supports avatar + name + text, but every real comment is「我」.
enum LocalDanmakuIdentity {
    static let displayName = "我"

    /// Deterministic palette index derived from the comment id — not a user account.
    static let avatarPalette: [UInt32] = [
        0xF472B6,
        0xA78BFA,
        0xFACC15,
        0x60A5FA,
        0xF87171,
        0xFB923C,
        0x34D399,
        0x8B5CF6
    ]

    static func displayName(for _: DanmakuRecord) -> String {
        displayName
    }

    static func avatarLetter(for _: DanmakuRecord) -> String {
        displayName
    }

    static func avatarColorSeed(for id: UUID) -> Int {
        let u = id.uuid
        let value = Int(u.0) &+ Int(u.1) &* 3 &+ Int(u.2) &* 5 &+ Int(u.3) &* 7
            &+ Int(u.4) &* 11 &+ Int(u.5) &* 13 &+ Int(u.6) &* 17 &+ Int(u.7) &* 19
        return abs(value) % avatarPalette.count
    }

    static func avatarHex(for id: UUID) -> UInt32 {
        avatarPalette[avatarColorSeed(for: id)]
    }
}
