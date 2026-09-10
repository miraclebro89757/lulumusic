import Foundation
import MediaPlayer
import UIKit

enum NowPlayingCenter {
    static func update(item: PlaybackItem?, currentTime: TimeInterval, duration: TimeInterval, isPlaying: Bool) {
        let center = MPNowPlayingInfoCenter.default()
        guard let item else {
            center.nowPlayingInfo = nil
            return
        }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: item.title,
            MPMediaItemPropertyArtist: item.artist,
            MPMediaItemPropertyAlbumTitle: item.album,
            MPMediaItemPropertyPlaybackDuration: duration > 0 ? duration : item.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: max(0, currentTime),
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue
        ]

        if let artworkURL = item.artworkURL,
           let data = try? Data(contentsOf: artworkURL),
           let image = UIImage(data: data) {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            info[MPMediaItemPropertyArtwork] = artwork
        }

        center.nowPlayingInfo = info
    }

    static func configureRemoteCommands(player: PlayerEngine) {
        let command = MPRemoteCommandCenter.shared()
        command.playCommand.isEnabled = true
        command.pauseCommand.isEnabled = true
        command.togglePlayPauseCommand.isEnabled = true
        command.nextTrackCommand.isEnabled = true
        command.previousTrackCommand.isEnabled = true
        command.changePlaybackPositionCommand.isEnabled = true
        command.stopCommand.isEnabled = true

        command.playCommand.addTarget { _ in
            Task { @MainActor in player.play() }
            return .success
        }
        command.pauseCommand.addTarget { _ in
            Task { @MainActor in player.pause() }
            return .success
        }
        command.togglePlayPauseCommand.addTarget { _ in
            Task { @MainActor in player.togglePlayPause() }
            return .success
        }
        command.nextTrackCommand.addTarget { _ in
            Task { @MainActor in player.playNext() }
            return .success
        }
        command.previousTrackCommand.addTarget { _ in
            Task { @MainActor in player.playPrevious() }
            return .success
        }
        command.stopCommand.addTarget { _ in
            Task { @MainActor in player.pause() }
            return .success
        }
        command.changePlaybackPositionCommand.addTarget { event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            Task { @MainActor in player.seek(to: event.positionTime) }
            return .success
        }
    }
}
