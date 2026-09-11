import Foundation
import Network

/// Triggers the iOS Local Network permission prompt so LAN HTTP clients can connect.
enum LocalNetworkAccess {
    private static var browser: NWBrowser?
    private static var probeConnection: NWConnection?

    static func request() {
        end()
        let params = NWParameters.udp
        params.includePeerToPeer = true
        let browser = NWBrowser(for: .bonjour(type: LANBindPolicy.bonjourServiceType, domain: nil), using: params)
        browser.stateUpdateHandler = { _ in }
        browser.start(queue: .main)
        Self.browser = browser

        // Connecting to the advertised LAN IP (not loopback) also surfaces the prompt on enter.
        if let ip = LocalIPAddress.lanIPv4Addresses().first,
           let port = NWEndpoint.Port(rawValue: 9) {
            let connection = NWConnection(host: NWEndpoint.Host(ip), port: port, using: .udp)
            connection.start(queue: .main)
            Self.probeConnection = connection
        }
    }

    static func end() {
        browser?.cancel()
        browser = nil
        probeConnection?.cancel()
        probeConnection = nil
    }
}
