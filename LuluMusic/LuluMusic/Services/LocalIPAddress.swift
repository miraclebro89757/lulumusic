import Foundation
#if canImport(Darwin)
import Darwin
#endif

enum LocalIPAddress {
    /// IPv4 addresses on likely Wi‑Fi / Ethernet interfaces, excluding loopback and cellular.
    static func lanIPv4Addresses() -> [String] {
        var addresses: [String] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return [] }
        defer { freeifaddrs(ifaddr) }

        let skipPrefixes = ["lo", "pdp_ip", "ipsec", "utun", "awdl", "llw"]
        var pointer: UnsafeMutablePointer<ifaddrs>? = first
        while let iface = pointer {
            defer { pointer = iface.pointee.ifa_next }
            let flags = Int32(iface.pointee.ifa_flags)
            guard (flags & IFF_UP) == IFF_UP, (flags & IFF_LOOPBACK) == 0 else { continue }
            guard let addr = iface.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_INET) else { continue }

            let name = String(cString: iface.pointee.ifa_name)
            if skipPrefixes.contains(where: { name.hasPrefix($0) }) { continue }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let result = getnameinfo(
                addr,
                socklen_t(addr.pointee.sa_len),
                &hostname,
                socklen_t(hostname.count),
                nil,
                0,
                NI_NUMERICHOST
            )
            guard result == 0 else { continue }
            let ip = String(cString: hostname)
            if ip.hasPrefix("127.") { continue }
            if !addresses.contains(ip) {
                addresses.append(ip)
            }
        }

        return addresses.sorted { lhs, rhs in
            let leftWiFi = lhsPrefersWiFi(lhs)
            let rightWiFi = lhsPrefersWiFi(rhs)
            if leftWiFi != rightWiFi { return leftWiFi }
            return lhs < rhs
        }
    }

    private static func lhsPrefersWiFi(_ ip: String) -> Bool {
        ip.hasPrefix("192.168.") || ip.hasPrefix("10.") || ip.hasPrefix("172.")
    }
}
