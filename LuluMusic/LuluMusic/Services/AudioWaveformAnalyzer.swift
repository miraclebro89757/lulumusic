import AVFoundation
import Foundation

enum AudioWaveformAnalyzer {
    static func peaks(from url: URL, barCount: Int = 52) async -> [Float] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: readPeaks(url: url, barCount: barCount))
            }
        }
    }

    private static func readPeaks(url: URL, barCount: Int) -> [Float] {
        let empty = Array(repeating: Float(0), count: max(1, barCount))
        let asset = TrackDuration.preciseAsset(url: url)
        let ready = DispatchSemaphore(value: 0)
        var loadError: NSError?
        asset.loadValuesAsynchronously(forKeys: ["tracks", "duration"]) {
            ready.signal()
        }
        if ready.wait(timeout: .now() + 8) == .timedOut {
            return empty
        }
        guard asset.statusOfValue(forKey: "tracks", error: &loadError) == .loaded,
              let track = asset.tracks(withMediaType: .audio).first else {
            return empty
        }

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        guard let reader = try? AVAssetReader(asset: asset) else { return empty }
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
        output.alwaysCopiesSampleData = false
        guard reader.canAdd(output) else { return empty }
        reader.add(output)
        guard reader.startReading() else { return empty }

        let durationMS = PlaybackClock.milliseconds(
            fromPlayerSeconds: TrackDuration.playbackSeconds(from: asset.duration)
        )
        var peaks = empty
        while let buffer = output.copyNextSampleBuffer() {
            let pts = CMSampleBufferGetPresentationTimeStamp(buffer)
            let ptsSeconds = pts.seconds
            let atMS = PlaybackClock.milliseconds(
                fromPlayerSeconds: ptsSeconds.isFinite ? max(0, ptsSeconds) : 0
            )
            if let block = CMSampleBufferGetDataBuffer(buffer) {
                let length = CMBlockBufferGetDataLength(block)
                var data = Data(count: length)
                data.withUnsafeMutableBytes { ptr in
                    guard let base = ptr.baseAddress else { return }
                    _ = CMBlockBufferCopyDataBytes(block, atOffset: 0, dataLength: length, destination: base)
                }
                let count = length / MemoryLayout<Int16>.size
                var peak: Float = 0
                data.withUnsafeBytes { raw in
                    let ints = raw.bindMemory(to: Int16.self)
                    let step = max(1, count / 512)
                    var i = 0
                    while i < count {
                        peak = max(peak, abs(Float(ints[i]) / Float(Int16.max)))
                        i += step
                    }
                }
                WaveformPeakSampler.accumulate(amplitude: peak, atMS: atMS, durationMS: durationMS, into: &peaks)
            }
        }
        return WaveformPeakSampler.normalize(peaks)
    }
}
