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
    var navigator = PlaybackNavigator(mode: .sequential)
    var danmakuEnabled = true
    var resumeStore: ResumeStoring = UserDefaultsResumeStore()

    var playbackMode: PlaybackMode {
        get { navigator.mode }
        set {
            let old = navigator.mode
            navigator.mode = newValue
            applyModeChange(from: old, to: newValue)
        }
    }

    var current: PlaybackItem? {
        queue.indices.contains(currentIndex) ? queue[currentIndex] : nil
    }

    var playbackModeTitle: String { navigator.mode.title }

    var currentTimeMS: Int { PlaybackClock.milliseconds(fromPlayerSeconds: currentTime) }

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var interruptionObserver: NSObjectProtocol?
    private var routeObserver: NSObjectProtocol?
    private var unshuffledQueue: [PlaybackItem] = []
    private var remoteConfigured = false
    private var shouldResumeAfterInterruption = false
    private var lastResumePositionMS = -1
    private var isSeeking = false
    private var seekGeneration = 0
    private var pendingAutoplay = false
    private var statusObserver: NSKeyValueObservation?
    private var durationObserver: NSKeyValueObservation?
    private var timeControlObserver: NSKeyValueObservation?
    private var pendingPlay = false
    private(set) var lastPlayIntent: AudiblePlayIntent?

    init() {
        AudioSessionController.activatePlayback()
        observeAudioSession()
    }

    func play(tracks: [Track], startAt index: Int) {
        guard !tracks.isEmpty else { return }
        let items = tracks.map(PlaybackItem.init)
        play(items: items, startAt: min(max(0, index), items.count - 1))
    }

    func play(items: [PlaybackItem], startAt index: Int, resume: Bool = false) {
        unshuffledQueue = items
        if navigator.mode == .shuffle {
            queue = PlaybackNavigator.shuffledOrder(of: items, pinning: index)
            currentIndex = queue.firstIndex(where: { $0.id == items[index].id }) ?? 0
        } else {
            queue = items
            currentIndex = index
        }
        loadCurrent(autoplay: true, resume: resume)
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
        _ = AudioSessionController.activatePlayback()
        guard let item = current else { return }
        let fileExists = FileManager.default.fileExists(atPath: item.fileURL.path)
        if player?.currentItem == nil || player?.currentItem?.status == .failed {
            lastPlayIntent = AudiblePlayback.playIntent(
                hasCurrentTrack: true,
                fileExists: fileExists,
                itemReadiness: .unknown
            )
            guard lastPlayIntent != nil else {
                pendingPlay = false
                pendingAutoplay = false
                isPlaying = false
                return
            }
            pendingPlay = true
            pendingAutoplay = true
            loadCurrent(autoplay: true)
            return
        }
        let readiness = PlayerItemReadiness(statusRawValue: player?.currentItem?.status.rawValue ?? 0)
        lastPlayIntent = AudiblePlayback.playIntent(
            hasCurrentTrack: true,
            fileExists: fileExists,
            itemReadiness: readiness
        )
        guard lastPlayIntent != nil else {
            pendingPlay = false
            pendingAutoplay = false
            isPlaying = false
            return
        }
        pendingPlay = true
        pendingAutoplay = true
        issueAudiblePlay()
    }

    func pause() {
        pendingPlay = false
        pendingAutoplay = false
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
        if userInitiated {
            currentIndex = navigator.indexOnUserNext(currentIndex: currentIndex, count: queue.count)
            loadCurrent(autoplay: true)
            return
        }
        switch navigator.actionOnTrackEnd(currentIndex: currentIndex, count: queue.count) {
        case .replayCurrent:
            seek(to: 0)
            play()
        case .advanceTo(let index):
            currentIndex = index
            loadCurrent(autoplay: true)
        case .stop:
            seek(to: 0)
            pause()
        }
    }

    func playPrevious() {
        guard !queue.isEmpty else { return }
        switch navigator.actionOnUserPrevious(
            currentIndex: currentIndex,
            count: queue.count,
            positionMS: currentTimeMS
        ) {
        case .seekToStart:
            seek(to: 0)
        case .previousIndex(let index):
            currentIndex = index
            loadCurrent(autoplay: true)
        }
    }

    func livePlayerMilliseconds() -> Int {
        if !isSeeking {
            snapshotFromAVPlayer()
        }
        return currentTimeMS
    }

    func seek(to time: TimeInterval) {
        let normalized = TrackDuration.playbackSeconds(fromRaw: time)
        let clamped = duration > 0 ? min(normalized, duration) : normalized
        let target = max(0, clamped)
        isSeeking = true
        seekGeneration += 1
        let generation = seekGeneration
        currentTime = target
        persistResume()
        publishNowPlaying()
        let cm = CMTime(seconds: target, preferredTimescale: 600)
        guard let player else {
            isSeeking = false
            return
        }
        player.seek(to: cm, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
            Task { @MainActor [weak self] in
                guard let self, generation == self.seekGeneration else { return }
                self.isSeeking = false
                if finished {
                    self.snapshotFromAVPlayer()
                } else {
                    self.currentTime = target
                }
                self.persistResume()
                self.publishNowPlaying()
            }
        }
    }

    func cyclePlaybackMode() {
        let old = navigator.mode
        navigator.cycle()
        applyModeChange(from: old, to: navigator.mode)
        persistResume()
        publishNowPlaying()
    }

    func restoreSession(library: [Track]) {
        let state = resumeStore.load()
        danmakuEnabled = state.danmakuEnabled
        navigator.mode = state.mode
        guard let trackID = state.trackID,
              let index = library.firstIndex(where: { $0.id == trackID }) else { return }
        unshuffledQueue = library.map(PlaybackItem.init)
        if navigator.mode == .shuffle {
            queue = PlaybackNavigator.shuffledOrder(of: unshuffledQueue, pinning: index)
            currentIndex = queue.firstIndex(where: { $0.id == trackID }) ?? 0
        } else {
            queue = unshuffledQueue
            currentIndex = index
        }
        loadCurrent(autoplay: false, resume: false)
        let position = state.positionMS > 0 ? state.positionMS : (queue[currentIndex].lastPositionMS)
        if position > 0 {
            seek(to: TimeInterval(position) / 1000.0)
        }
        pause()
    }

    func persistResume() {
        resumeStore.save(
            PlaybackResumeState(
                trackID: current?.id,
                positionMS: currentTimeMS,
                danmakuEnabled: danmakuEnabled,
                mode: navigator.mode
            )
        )
    }

    private func applyModeChange(from old: PlaybackMode, to new: PlaybackMode) {
        guard let currentID = current?.id else { return }
        if new == .shuffle && old != .shuffle {
            if unshuffledQueue.isEmpty { unshuffledQueue = queue }
            queue = PlaybackNavigator.shuffledOrder(
                of: unshuffledQueue,
                pinning: unshuffledQueue.firstIndex(where: { $0.id == currentID }) ?? 0
            )
        } else if old == .shuffle && new != .shuffle {
            let source = unshuffledQueue.isEmpty ? queue : unshuffledQueue
            queue = source
        }
        currentIndex = queue.firstIndex(where: { $0.id == currentID }) ?? 0
    }

    func removeFromQueue(trackID: UUID) {
        let wasCurrent = current?.id == trackID
        let removedIndex = queue.firstIndex(where: { $0.id == trackID })
        queue.removeAll { $0.id == trackID }
        unshuffledQueue.removeAll { $0.id == trackID }
        if queue.isEmpty {
            stopCompletely()
            return
        }
        if wasCurrent {
            currentIndex = min(currentIndex, queue.count - 1)
            loadCurrent(autoplay: isPlaying)
        } else if let removedIndex, removedIndex < currentIndex {
            currentIndex -= 1
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
        persistResume()
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        queue = []
        unshuffledQueue = []
        currentIndex = 0
        isPlaying = false
        pendingPlay = false
        pendingAutoplay = false
        lastPlayIntent = nil
        currentTime = 0
        duration = 0
        isSeeking = false
        statusObserver?.invalidate()
        durationObserver?.invalidate()
        timeControlObserver?.invalidate()
        statusObserver = nil
        durationObserver = nil
        timeControlObserver = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }


    private func beginPlayback() {
        pendingPlay = true
        pendingAutoplay = true
        issueAudiblePlay()
    }

    private func loadCurrent(autoplay: Bool, resume: Bool = false) {
        guard let item = current else {
            stopCompletely()
            return
        }
        guard FileManager.default.fileExists(atPath: item.fileURL.path) else {
            isPlaying = false
            pendingAutoplay = false
            pendingPlay = false
            publishNowPlaying()
            return
        }
        _ = AudioSessionController.activatePlayback()
        configureRemoteIfNeeded()

        if let observer = timeObserver, let player {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        statusObserver?.invalidate()
        durationObserver?.invalidate()
        statusObserver = nil
        durationObserver = nil
        isSeeking = false

        pendingPlay = autoplay
        let playerItem = AVPlayerItem(url: item.fileURL)
        if player == nil {
            player = AVPlayer(playerItem: playerItem)
            player?.actionAtItemEnd = .pause
            bindTimeControlObserver()
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }
        configureAudibleOutput()

        duration = TrackDuration.playbackSeconds(fromRaw: item.duration)
        currentTime = 0
        observeItemTiming(playerItem)

        let interval = CMTime(seconds: 0.05, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in
                self?.applyAVPlayerTime(time)
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

        if resume, item.lastPositionMS > 0 {
            seek(to: TimeInterval(item.lastPositionMS) / 1000.0)
        }

        if autoplay {
            pendingAutoplay = true
            pendingPlay = true
            if playerItem.status == .readyToPlay {
                issueAudiblePlay()
            }
            // else status observer will call issueAudiblePlay when readyToPlay
        } else {
            pendingAutoplay = false
            pendingPlay = false
            isPlaying = false
        }
        persistResume()
        publishNowPlaying()
    }

    private func issueAudiblePlay() {
        _ = AudioSessionController.activatePlayback()
        configureAudibleOutput()
        guard let player else { return }
        if player.timeControlStatus == .playing, player.rate > 0 { return }
        let fileExists = current.map { FileManager.default.fileExists(atPath: $0.fileURL.path) } ?? false
        let readiness = PlayerItemReadiness(statusRawValue: player.currentItem?.status.rawValue ?? 0)
        let intent = AudiblePlayback.playIntent(
            hasCurrentTrack: current != nil,
            fileExists: fileExists,
            itemReadiness: readiness
        )
        lastPlayIntent = intent
        guard let intent, intent.callAVPlayerPlay else {
            pendingPlay = false
            pendingAutoplay = false
            syncPlayingFromPlayer()
            return
        }
        if intent.playImmediately {
            pendingAutoplay = false
            player.playImmediately(atRate: intent.rate)
        } else {
            pendingAutoplay = true
            player.play()
        }
        syncPlayingFromPlayer()
        publishNowPlaying()
    }

    private func configureAudibleOutput() {
        guard let player else { return }
        player.isMuted = false
        player.volume = 1
        player.automaticallyWaitsToMinimizeStalling = false
    }

    private func bindTimeControlObserver() {
        timeControlObserver?.invalidate()
        timeControlObserver = player?.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.syncPlayingFromPlayer()
            }
        }
    }

    private func syncPlayingFromPlayer() {
        let kind = TimeControlKind(statusRawValue: player?.timeControlStatus.rawValue ?? 0)
        isPlaying = AudiblePlayback.uiIsPlaying(optimisticIsPlaying: pendingPlay, timeControl: kind)
        if kind == .playing {
            pendingPlay = true
        }
        publishNowPlaying()
    }

    private func observeItemTiming(_ playerItem: AVPlayerItem) {
        applyItemDuration(playerItem)
        statusObserver = playerItem.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.applyItemDuration(item)
                self.handleItemStatus(item)
            }
        }
        durationObserver = playerItem.observe(\.duration, options: [.new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                self?.applyItemDuration(item)
            }
        }
    }

    private func handleItemStatus(_ item: AVPlayerItem) {
        let readiness = PlayerItemReadiness(statusRawValue: item.status.rawValue)
        if item.status == .readyToPlay, pendingPlay || pendingAutoplay {
            issueAudiblePlay()
        } else if readiness == .failed {
            pendingPlay = false
            pendingAutoplay = false
            isPlaying = false
            publishNowPlaying()
        }
    }

    private func applyItemDuration(_ item: AVPlayerItem) {
        let seconds = TrackDuration.playbackSeconds(from: item.duration)
        guard seconds > 0 else { return }
        duration = seconds
        publishNowPlaying()
    }

    private func applyAVPlayerTime(_ observed: CMTime) {
        if !isSeeking {
            if let live = player?.currentTime(), live.isNumeric {
                let seconds = live.seconds
                currentTime = seconds.isFinite ? max(0, seconds) : 0
            } else if observed.isNumeric {
                let seconds = observed.seconds
                currentTime = seconds.isFinite ? max(0, seconds) : 0
            }
        }
        if let item = player?.currentItem {
            applyItemDuration(item)
        }
        maybePersistResume()
    }

    private func snapshotFromAVPlayer() {
        guard let live = player?.currentTime(), live.isNumeric else { return }
        let seconds = live.seconds
        if seconds.isFinite {
            currentTime = max(0, seconds)
        }
    }

    private func maybePersistResume() {
        let ms = currentTimeMS
        guard abs(ms - lastResumePositionMS) >= 1_000 else { return }
        lastResumePositionMS = ms
        persistResume()
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
}

