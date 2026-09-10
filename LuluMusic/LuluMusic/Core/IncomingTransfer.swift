import Foundation

/// F01: Files / AirDrop inbound audio.
enum IncomingTransfer {
    static var supportsMultipleSelection: Bool { true }

    static func shouldImport(url: URL) -> Bool {
        ImportFormatAllowlist.isAllowed(url: url)
    }

    static func importableURLs(from urls: [URL]) -> [URL] {
        urls.filter(shouldImport)
    }
}
