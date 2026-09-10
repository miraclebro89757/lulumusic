import Foundation

/// v0.1 P0 formats (F03). OGG is explicitly out of scope.
enum ImportFormatAllowlist {
    static let allowedExtensions: Set<String> = ["mp3", "m4a", "aac", "wav", "flac"]
    static let rejectedExtensions: Set<String> = ["ogg", "oga", "opus"]

    static func isAllowed(fileName: String) -> Bool {
        allowedExtensions.contains(ext(fileName))
    }

    static func isAllowed(url: URL) -> Bool {
        isAllowed(fileName: url.lastPathComponent)
    }

    static func isRejectedOGG(fileName: String) -> Bool {
        rejectedExtensions.contains(ext(fileName))
    }

    static func ext(_ fileName: String) -> String {
        URL(fileURLWithPath: fileName).pathExtension.lowercased()
    }
}
