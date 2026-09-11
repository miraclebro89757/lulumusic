import AVFoundation
import Foundation

enum AudioWaveformAnalyzer {
    static func peaks(from url: URL, barCount: Int = 52) async -> [Float] {
        await Task.detached(priority: .userInitiated) {
            readPeaks(url: url, barCount: barCount)
        }.value
    }

    private static func readPeaks(url: URL, barCount: Int) -> [Float] {
        let asset = AVURLAsset(url: url)
        guard let track = asset.tracks(withMediaType: .audio).first else {
            return WaveformPeakSampler.downsample(samples: [], barCount: barCount)
        }
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        guard let reader = try? AVAssetReader(asset: asset) else {
            return WaveformPeakSampler.downsample(samples: [], barCount: barCount)
        }
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
        output.alwaysCopiesSampleData = false
        guard reader.canAdd(output) else {
            return WaveformPeakSampler.downsample(samples: [], barCount: barCount)
        }
        reader.add(output)
        guard reader.startReading() else {
            return WaveformPeakSampler.downsample(samples: [], barCount: barCount)
        }

        var samples: [Float] = []
        samples.reserveCapacity(64_000)
        while let buffer = output.copyNextSampleBuffer() {
            defer { CMSampleBufferInvalidate(buffer) }
            guard let block = CMSampleBufferGetDataBuffer(buffer) else { continue }
            let length = CMBlockBufferGetDataLength(block)
            var data = Data(count: length)
            data.withUnsafeMutableBytes { ptr in
                guard let base = ptr.baseAddress else { return }
                _ = CMBlockBufferCopyDataBytes(block, atOffset: 0, dataLength: length, destination: base)
            }
            let count = length / MemoryLayout<Int16>.size
            data.withUnsafeBytes { raw in
                let ints = raw.bindMemory(to: Int16.self)
                let step = max(1, count / 4_000)
                var i = 0
                while i < count {
                    samples.append(abs(Float(ints[i]) / Float(Int16.max)))
                    i += step
                }
            }
            if samples.count > 200_000 { break }
        }
        return WaveformPeakSampler.downsample(samples: samples, barCount: barCount)
    }
}
