import Foundation
import Network
import SystemConfiguration.CaptiveNetwork

class NetworkInfoService {
    
    func fetchNetworkSummary() async -> NetworkSummary {
        var summary = NetworkSummary()
        
        // 1. IP & Interface Info
        let ipDetails = getLocalIPAddresses()
        summary.localIpv4 = ipDetails.ipv4
        summary.localIpv6 = ipDetails.ipv6
        summary.subnetMask = ipDetails.netmask
        summary.interfaceName = ipDetails.interfaceName
        
        if ipDetails.ipv4 != "-" {
            summary.isConnected = true
            summary.connectionType = ipDetails.interfaceName.starts(with: "en") ? .wifi : .cellular
            let parts = ipDetails.ipv4.split(separator: ".")
            if parts.count == 4 {
                summary.defaultGateway = "\(parts[0]).\(parts[1]).\(parts[2]).1"
                summary.broadcastIp = "\(parts[0]).\(parts[1]).\(parts[2]).255"
            }
        }
        
        // 2. Wi-Fi SSID / BSSID
        if let wifiInfo = fetchCurrentWifiInfo() {
            summary.wifiSsid = wifiInfo.ssid
            summary.wifiBssid = wifiInfo.bssid
            summary.connectionType = .wifi
        }
        
        // 3. DNS Servers
        summary.dnsServers = getSystemDnsServers()
        
        // 4. Public IP & Geo Location
        do {
            if let url = URL(string: "https://ipwhois.app/json/") {
                let (data, response) = try await URLSession.shared.data(from: url)
                if (response as? HTTPURLResponse)?.statusCode == 200 {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        summary.publicIp = json["ip"] as? String ?? "-"
                        summary.ispName = json["isp"] as? String ?? "-"
                        let city = json["city"] as? String ?? ""
                        let country = json["country"] as? String ?? ""
                        summary.location = city.isEmpty ? country : "\(city), \(country)"
                    }
                }
            }
        } catch {}
        
        return summary
    }
    
    private func fetchCurrentWifiInfo() -> (ssid: String, bssid: String)? {
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else { return nil }
        for interface in interfaces {
            guard let info = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any] else { continue }
            let ssid = info[kCNNetworkInfoKeySSID as String] as? String ?? "-"
            let bssid = info[kCNNetworkInfoKeyBSSID as String] as? String ?? "-"
            return (ssid, bssid)
        }
        return nil
    }
    
    private func getLocalIPAddresses() -> (ipv4: String, ipv6: String, netmask: String, interfaceName: String) {
        var ipv4 = "-"
        var ipv6 = "-"
        var netmask = "255.255.255.0"
        var interfaceName = "en0"
        
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return (ipv4, ipv6, netmask, interfaceName)
        }
        defer { freeifaddrs(ifaddr) }
        
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            let name = String(cString: interface.ifa_name)
            
            // Check WiFi (en0) or Cellular (pdp_ip0)
            if name.starts(with: "en") || name.starts(with: "pdp_ip") {
                if addrFamily == UInt8(AF_INET) {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, 0, NI_NUMERICHOST)
                    let ipStr = String(cString: hostname)
                    if !ipStr.hasPrefix("127.") {
                        ipv4 = ipStr
                        interfaceName = name
                    }
                } else if addrFamily == UInt8(AF_INET6) {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, 0, NI_NUMERICHOST)
                    let ipStr = String(cString: hostname)
                    if !ipStr.hasPrefix("fe80") && !ipStr.hasPrefix("::1") {
                        ipv6 = ipStr
                    }
                }
            }
        }
        
        return (ipv4, ipv6, netmask, interfaceName)
    }
    
    private func getSystemDnsServers() -> [String] {
        var dnsServers: [String] = []
        if let config = res_9_state() {
            var state = config.pointee
            if res_9_ninit(&state) == 0 {
                for i in 0..<Int(state.nscount) {
                    let ns = state.nsaddr_list[i]
                    var ip = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                    var sin_addr = ns.sin_addr
                    if inet_ntop(AF_INET, &sin_addr, &ip, socklen_t(INET_ADDRSTRLEN)) != nil {
                        dnsServers.append(String(cString: ip))
                    }
                }
            }
            res_9_ndestroy(&state)
        }
        return dnsServers.isEmpty ? ["8.8.8.8", "1.1.1.1"] : dnsServers
    }
}
