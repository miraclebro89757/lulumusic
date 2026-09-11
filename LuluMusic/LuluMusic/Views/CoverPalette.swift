import SwiftUI
import UIKit

/// Cover-driven atmosphere. Play/accent stay purple; average color only tints background/waveform.
enum CoverPalette {
    private static var cache: [String: Color] = [:]

    static func atmosphere(url: URL?, seed: String) -> LinearGradient {
        if let avg = average(from: url) {
            return LinearGradient(
                colors: [
                    avg.opacity(0.62),
                    avg.opacity(0.22),
                    LoveSongTheme.stageBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        return LoveSongTheme.hashGradient(for: seed)
    }

    static func waveformTint(from url: URL?) -> Color {
        guard let avg = average(from: url) else { return LoveSongTheme.accent }
        return avg.blended(with: LoveSongTheme.accent, t: 0.72)
    }

    static func average(from url: URL?) -> Color? {
        guard let url else { return nil }
        let key = url.path
        if let cached = cache[key] { return cached }
        guard let image = UIImage(contentsOfFile: key), let sampled = sample(image) else { return nil }
        cache[key] = sampled
        return sampled
    }

    private static func sample(_ image: UIImage) -> Color? {
        guard let cg = image.cgImage else { return nil }
        let width = 8
        let height = 8
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let ctx = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        ctx.interpolationQuality = .low
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
        var r = 0, g = 0, b = 0, n = 0
        for i in stride(from: 0, to: pixels.count, by: 4) {
            if pixels[i + 3] < 16 { continue }
            r += Int(pixels[i])
            g += Int(pixels[i + 1])
            b += Int(pixels[i + 2])
            n += 1
        }
        guard n > 0 else { return nil }
        return Color(
            red: Double(r) / Double(n) / 255,
            green: Double(g) / Double(n) / 255,
            blue: Double(b) / Double(n) / 255
        )
    }
}

extension Color {
    func blended(with other: Color, t: Double) -> Color {
        let a = UIColor(self)
        let b = UIColor(other)
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        let k = CGFloat(min(1, max(0, t)))
        return Color(
            red: Double(ar + (br - ar) * k),
            green: Double(ag + (bg - ag) * k),
            blue: Double(ab + (bb - ab) * k)
        )
    }
}
