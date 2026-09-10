import Foundation

enum AppRuntimePhase: Equatable {
    case foregroundActive
    case inactive
    case background
    case locked
}

enum WebImportLifecycle {
    /// Server runs only while the import page is visible in the foreground (F02).
    static func shouldServe(pageVisible: Bool, phase: AppRuntimePhase) -> Bool {
        pageVisible && phase == .foregroundActive
    }
}

enum LANBindPolicy {
    static func isAdvertisableLAN(_ ip: String) -> Bool {
        if ip.isEmpty || ip == "127.0.0.1" || ip.hasPrefix("169.254.") { return false }
        if ip.hasPrefix("10.") { return true }
        if ip.hasPrefix("192.168.") { return true }
        if ip.hasPrefix("172.") {
            let parts = ip.split(separator: ".")
            if parts.count >= 2, let second = Int(parts[1]), (16...31).contains(second) {
                return true
            }
        }
        return false
    }

    static func advertisedURL(ips: [String], port: UInt16) -> String? {
        guard let ip = ips.first(where: isAdvertisableLAN) else { return nil }
        return "http://\(ip):\(port)"
    }

    static func shouldBindInterface(_ name: String) -> Bool {
        if name.hasPrefix("lo") || name.hasPrefix("pdp_ip") || name.hasPrefix("ipsec") { return false }
        if name.hasPrefix("utun") || name.hasPrefix("awdl") { return false }
        return name.hasPrefix("en") || name.hasPrefix("bridge") || name.hasPrefix("wlan")
    }
}

enum WebImportRoute: Equatable {
    case page
    case pair
    case upload
    case rejectedDelete
    case unauthorized
    case notFound
}

enum WebImportRouter {
    static var allowsDeleteFromWeb: Bool { false }

    static func route(method: String, path: String, authorized: Bool) -> WebImportRoute {
        let upper = method.uppercased()
        if upper == "DELETE" { return .rejectedDelete }

        let clean = path.split(separator: "?").first.map(String.init) ?? path
        if upper == "GET" && (clean == "/" || clean == "/index.html") {
            return .page
        }
        if upper == "POST" && (clean == "/pair" || clean.hasSuffix("/pair")) {
            return .pair
        }
        if upper == "POST" && (clean == "/upload" || clean.hasSuffix("/upload")) {
            return authorized ? .upload : .unauthorized
        }
        return .notFound
    }
}
