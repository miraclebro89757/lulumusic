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

struct LANInterfaceAddress: Equatable {
    var name: String
    var ip: String
}

enum LANBindPolicy {
    static let listenerBindsIPv4 = true
    static let listenerAcceptLocalOnly = false
    static let listenerIncludePeerToPeer = true
    static let listenerAdvertisesBonjour = true
    static let bonjourServiceType = "_lovesong._tcp"
    static let requestsLocalNetworkAccessOnEnter = true
    static let showsManualStartStop = false
    static let showsQRCode = false
    static let stayOpenBanner = "上传时请保持本页打开，不要关闭或切走，否则传输会中断"

    static func isAdvertisableLAN(_ ip: String) -> Bool {
        if ip.isEmpty || ip == "127.0.0.1" || ip.hasPrefix("127.") || ip.hasPrefix("169.254.") { return false }
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
        let ranked = ips.filter(isAdvertisableLAN).sorted { ipRank($0) < ipRank($1) }
        guard let ip = ranked.first else { return nil }
        return "http://\(ip):\(port)"
    }

    static func advertisedURL(from addresses: [LANInterfaceAddress], port: UInt16) -> String? {
        guard let ip = advertisedIPv4(from: addresses) else { return nil }
        return "http://\(ip):\(port)"
    }

    static func advertisedIPv4(from addresses: [LANInterfaceAddress]) -> String? {
        rankedAddresses(addresses).first?.ip
    }

    static func rankedIPv4(from addresses: [LANInterfaceAddress]) -> [String] {
        rankedAddresses(addresses).map(\.ip)
    }

    static func shouldBindInterface(_ name: String) -> Bool {
        if name.hasPrefix("lo") || name.hasPrefix("pdp_ip") || name.hasPrefix("ipsec") { return false }
        if name.hasPrefix("utun") || name.hasPrefix("awdl") || name.hasPrefix("llw") { return false }
        return name.hasPrefix("en") || name.hasPrefix("bridge") || name.hasPrefix("wlan")
    }

    private static func rankedAddresses(_ addresses: [LANInterfaceAddress]) -> [LANInterfaceAddress] {
        addresses
            .filter { shouldBindInterface($0.name) && isAdvertisableLAN($0.ip) }
            .sorted { lhs, rhs in
                let left = rank(lhs)
                let right = rank(rhs)
                if left != right { return left < right }
                return lhs.ip < rhs.ip
            }
    }

    private static func rank(_ addr: LANInterfaceAddress) -> (Int, Int) {
        let iface: Int
        if addr.name == "en0" {
            iface = 0
        } else if addr.name.hasPrefix("en") || addr.name.hasPrefix("wlan") {
            iface = 1
        } else if addr.name.hasPrefix("bridge") {
            iface = 2
        } else {
            iface = 3
        }
        return (iface, ipRank(addr.ip))
    }

    private static func ipRank(_ ip: String) -> Int {
        if ip.hasPrefix("192.168.") { return 0 }
        if ip.hasPrefix("172.") {
            let parts = ip.split(separator: ".")
            if parts.count >= 2, let second = Int(parts[1]), (16...31).contains(second) {
                return 1
            }
        }
        if ip.hasPrefix("10.") { return 2 }
        return 3
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
