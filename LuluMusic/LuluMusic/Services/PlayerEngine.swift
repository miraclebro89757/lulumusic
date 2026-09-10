import AVFoundation
import Foundation
import MediaPlayer
import UIKit

@MainActor
@Observable
final class PlayerEngine {
    private(set) var queue: [PlaybackItem] = []
    private(set) var currentIndex: Int = 0
    private(set) var isPlaying = false
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    var repeatMode: RepeatMode = .off
    var isShuffle = false
    var isFullPlayerPresented = false

    var current: PlaybackItem? {
        queue.indices.contains(currentIndex) ? queue[currentIndex] : nil
    }

    var playbackModeTitle: String {
        if isShuffle { return L10n.shuffle }
        switch repeatMode {
        case .off: return L10n.sequential
        case .all: return L10n.repeatAll
        case .one: return L10n.repeatOne
        }
    }

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var interruptionObserver: NSObjectProtocol?
    private var routeObserver: NSObjectProtocol?
    private var unshuffledQueue: [PlaybackItem] = []
    private var remoteConfigured = false
    private var shouldResumeAfterInterruption = false

    init() {
        AudioSessionController.activatePlayback()
        observeAudioSession()
    }

    func play(tracks: [Track], startAt index: Int) {
        guard !tracks.isEmpty else { return }
        let items = tracks.map(PlaybackItem.init)
        play(items: items, startAt: min(max(0, index), items.count - 1))
    }

    func play(items: [PlaybackItem], startAt index: Int) {
        unshuffledQueue = items
        if isShuffle {
            queue = Self.shuffled(items, pinning: items[index].id)
            currentIndex = queue.firstIndex(where: { $0.id == items[index].id }) ?? 0
        } else {
            queue = items
            currentIndex = index
        }
        loadCurrent(autoplay: true)
    }

    func playNow(_ track: Track, library: [Track]) {
        if let idx = queue.firstIndex(where: { $0.id == track.id }) {
            currentIndex = idx
            loadCurrent(autoplay: true)
            return
        }
        if let idx = library.firstIndex(where: { $0.id == track.id }) {
            play(tracks: library, startAt: idx)
        } else {
            play(tracks: [track], startAt: 0)
        }
    }

    func enqueueNext(_ track: Track) {
        let item = PlaybackItem(track: track)
        let insertAt = min(currentIndex + 1, queue.count)
        queue.insert(item, at: insertAt)
        if let originalIndex = unshuffledQueue.firstIndex(where: { $0.id == current?.id }) {
            unshuffledQueue.insert(item, at: min(originalIndex + 1, unshuffledQueue.count))
        } else {
            unshuffledQueue.append(item)
        }
        if queue.count == 1 {
            currentIndex = 0
            loadCurrent(autoplay: true)
        }
    }

    func play() {
        AudioSessionController.activatePlayback()
        guard current != nil else { return }
        if player?.currentItem == nil {
            loadCurrent(autoplay: true)
            return
        }
        player?.play()
        isPlaying = true
        publishNowPlaying()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        publishNowPlaying()
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func playNext(userInitiated: Bool = true) {
        guard !queue.isEmpty else { return }
        if !userInitiated, repeatMode == .one {
            seek(to: 0)
            play()
            return
        }
        let last = queue.count - 1
        if currentIndex < last {
            currentIndex += 1
            loadCurrent(autoplay: true)
            return
        }
        if repeatMode == .all || isShuffle {
            currentIndex = 0
            loadCurrent(autoplay: true)
        } else {
            seek(to: 0)
            pause()
        }
    }

    func playPrevious() {
        guard !queue.isEmpty else { return }
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        if currentIndex > 0 {
            currentIndex -= 1
        } else if repeatMode == .all || isShuffle {
            currentIndex = queue.count - 1
        } else {
            seek(to: 0)
            return
        }
        loadCurrent(autoplay: true)
    }

    func seek(to time: TimeInterval) {
        let cm = CMTime(seconds: max(0, time), preferredTimescale: 600)
        player?.seek(to: cm, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = max(0, time)
        publishNowPlaying()
    }

    func cycleRepeatMode() {
        repeatMode = repeatMode.next
        publishNowPlaying()
    }

    func toggleShuffle() {
        isShuffle.toggle()
        guard let currentID = current?.id else { return }
        if isShuffle {
            if unshuffledQueue.isEmpty { unshuffledQueue = queue }
            queue = Self.shuffled(unshuffledQueue, pinning: currentID)
        } else {
            let source = unshuffledQueue.isEmpty ? queue : unshuffledQueue
            queue = source
        }
        currentIndex = queue.firstIndex(where: { $0.id == currentID }) ?? 0
    }

    func removeFromQueue(trackID: UUID) {
        let wasCurrent = current?.id == trackID
        queue.removeAll { $0.id == trackID }
        unshuffledQueue.removeAll { $0.id == trackID }
        if queue.isEmpty {
            stopCompletely()
            return
        }
        if wasCurrent {
            currentIndex = min(currentIndex, queue.count - 1)
            loadCurrent(autoplay: isPlaying)
        } else if currentIndex >= queue.count {
            currentIndex = queue.count - 1
        }
    }

    func jumpToQueueIndex(_ index: Int) {
        guard queue.indices.contains(index) else { return }
        currentIndex = index
        loadCurrent(autoplay: true)
    }

    private func stopCompletely() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        queue = []
        unshuffledQueue = []
        currentIndex = 0
        isPlaying = false
        currentTime = 0
        duration = 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    private func loadCurrent(autoplay: Bool) {
        guard let item = current else {
            stopCompletely()
            return
        }
        AudioSessionController.activatePlayback()
        configureRemoteIfNeeded()

        if let observer = timeObserver, let player {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }

        let playerItem = AVPlayerItem(url: item.fileURL)
        if player == nil {
            player = AVPlayer(playerItem: playerItem)
            player?.actionAtItemEnd = .pause
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }

        duration = item.duration
        currentTime = 0

        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.currentTime = time.seconds.isFinite ? time.seconds : 0
                if let d = self.player?.currentItem?.duration, d.isNumeric, !d.isIndefinite {
                    self.duration = d.seconds
                }
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.playNext(userInitiated: false)
            }
        }

        if autoplay {
            player?.play()
            isPlaying = true
        }
        publishNowPlaying()
    }

    private func publishNowPlaying() {
        NowPlayingCenter.update(
            item: current,
            currentTime: currentTime,
            duration: duration,
            isPlaying: isPlaying
        )
    }

    private func configureRemoteIfNeeded() {
        guard !remoteConfigured else { return }
        remoteConfigured = true
        NowPlayingCenter.configureRemoteCommands(player: self)
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }

    private func observeAudioSession() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor [weak self] in
                self?.handleInterruption(notification)
            }
        }
        routeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor [weak self] in
                self?.handleRouteChange(notification)
            }
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        switch type {
        case .began:
            shouldResumeAfterInterruption = isPlaying
            pause()
        case .ended:
            let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if shouldResumeAfterInterruption && options.contains(.shouldResume) {
                play()
            }
            shouldResumeAfterInterruption = false
        @unknown default:
            break
        }
    }

    private func handleRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
        if reason == .oldDeviceUnavailable {
            pause()
        }
    }

    private static func shuffled(_ items: [PlaybackItem], pinning id: UUID) -> [PlaybackItem] {
        guard let pinned = items.first(where: { $0.id == id }) else {
            return items.shuffled()
        }
        var rest = items.filter { $0.id != id }.shuffled()
        rest.insert(pinned, at: 0)
        return rest
    }
}
