import XCTest
@testable import LuluMusic

final class WaveformPeaksTests: XCTestCase {
    func testDownsampleUsesMaxAbsPerBucketNotTitleHash() {
        var samples = [Float](repeating: 0.05, count: 1_000)
        for i in 750..<780 {
            samples[i] = 1.0
        }
        let peaks = WaveformPeakSampler.downsample(samples: samples, barCount: 10)
        XCTAssertEqual(peaks.count, 10)
        XCTAssertGreaterThan(peaks[7], 0.9)
        XCTAssertLessThan(peaks[0], 0.2)
        XCTAssertFalse(WaveformPeakSampler.looksLikeHashedDecoration(peaks))
    }

    func testPlayheadBarIndexSyncsToCurrentTime() {
        XCTAssertEqual(
            WaveformPeakSampler.playheadBarIndex(currentMS: 0, durationMS: 10_000, barCount: 50),
            0
        )
        XCTAssertEqual(
            WaveformPeakSampler.playheadBarIndex(currentMS: 5_000, durationMS: 10_000, barCount: 50),
            25
        )
        XCTAssertEqual(
            WaveformPeakSampler.playheadBarIndex(currentMS: 10_000, durationMS: 10_000, barCount: 50),
            49
        )
        XCTAssertEqual(
            WaveformPeakSampler.playheadBarIndex(currentMS: 8_000, durationMS: 0, barCount: 50),
            0
        )
    }

    func testEmptySamplesYieldSilenceBars() {
        let peaks = WaveformPeakSampler.downsample(samples: [], barCount: 8)
        XCTAssertEqual(peaks.count, 8)
        XCTAssertTrue(peaks.allSatisfy { $0 == 0 })
    }
}
