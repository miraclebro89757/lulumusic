import Foundation
#if canImport(Darwin)
import Darwin
#endif

enum LocalIPAddress {
    /// IPv4 addresses on Wi‑Fi / Ethernet, excluding loopback, cellular, VPN, and link-local.
    static func lanIPv4Addresses() -> [String] {
        LANBindPolicy.rankedIPv4(from: lanInterfaceAddresses())
    }

    static func lanInterfaceAddresses() -> [LANInterfaceAddress] {
        var addresses: [LANInterfaceAddress] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return [] }
        defer { freeifaddrs(ifaddr) }

        var pointer: UnsafeMutablePointer<ifaddrs>? = first
        while let iface = pointer {
            defer { pointer = iface.pointee.ifa_next }
            let flags = Int32(iface.pointee.ifa_flags)
            guard (flags & IFF_UP) == IFF_UP, (flags & IFF_LOOPBACK) == 0 else { continue }
            guard let addr = iface.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_INET) else { continue }

            let name = String(cString: iface.pointee.ifa_name)
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
            let item = LANInterfaceAddress(name: name, ip: ip)
            if !addresses.contains(item) {
                addresses.append(item)
            }
        }
        return addresses
    }
}
