import AVFoundation
import Foundation
import os

enum AudioSessionController {
    static let requiredCategory = AudioSessionCategoryKind.playback
    private static let log = Logger(subsystem: "com.lulumusic.app", category: "AudioSession")

    @discardableResult
    static func activatePlayback() -> Bool {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            return true
        } catch {
            log.error("activatePlayback failed: \(error.localizedDescription, privacy: .public)")
            // Retry once with a looser option set used by many players.
            do {
                try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                try session.setActive(true)
                return true
            } catch {
                log.error("activatePlayback retry failed: \(error.localizedDescription, privacy: .public)")
                try? session.setCategory(.playback)
                try? session.setActive(true)
                return false
            }
        }
    }

    static func deactivate() {
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
}
