import Foundation

enum WaveformPeakSampler {
    /// Collapse PCM samples into `barCount` bars using max-abs per bucket, then normalize.
    static func downsample(samples: [Float], barCount: Int) -> [Float] {
        let count = max(1, barCount)
        guard !samples.isEmpty else { return Array(repeating: 0, count: count) }

        var peaks = Array(repeating: Float(0), count: count)
        for (index, sample) in samples.enumerated() {
            let bar = min(count - 1, (index * count) / max(1, samples.count))
            peaks[bar] = max(peaks[bar], abs(sample))
        }
        let peak = peaks.max() ?? 0
        if peak > 0 {
            peaks = peaks.map { $0 / peak }
        }
        return peaks
    }

    static func playheadBarIndex(currentMS: Int, durationMS: Int, barCount: Int) -> Int {
        let bars = max(1, barCount)
        guard durationMS > 0 else { return 0 }
        let fraction = min(1, max(0, Double(max(0, currentMS)) / Double(durationMS)))
        if fraction >= 1 { return bars - 1 }
        return min(bars - 1, Int(fraction * Double(bars)))
    }

    /// Hashed title-seed bars are uniformly mid/high with no silence. Real audio is not.
    static func looksLikeHashedDecoration(_ peaks: [Float]) -> Bool {
        guard peaks.count >= 8 else { return false }
        let nearSilent = peaks.filter { $0 < 0.15 }.count
        let minPeak = peaks.min() ?? 0
        return nearSilent == 0 && minPeak >= 0.2
    }
}
