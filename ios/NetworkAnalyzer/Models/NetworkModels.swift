import Foundation

enum ConnectionType: String {
    case wifi = "Wi-Fi"
    case cellular = "Cellular"
    case ethernet = "Ethernet"
    case none = "Disconnected"
}

struct NetworkSummary {
    var connectionType: ConnectionType = .none
    var interfaceName: String = "-"
    var isConnected: BooleanLiteralType = false
    
    // Wi-Fi Details
    var wifiSsid: String = "-"
    var wifiBssid: String = "-"
    
    // IP Addresses
    var localIpv4: String = "-"
    var localIpv6: String = "-"
    var subnetMask: String = "255.255.255.0"
    var defaultGateway: String = "-"
    var broadcastIp: String = "-"
    var macAddress: String = "-"
    
    // DNS & External
    var dnsServers: [String] = []
    var publicIp: String = "-"
    var ispName: String = "-"
    var location: String = "-"
}

struct DiscoveredDevice: Identifiable, Hashable {
    var id: String { ipAddress }
    let ipAddress: String
    var macAddress: String = ""
    var vendor: String = "Network Device"
    var hostname: String = ""
    var responseTimeMs: Double = 0
    var isGateway: Bool = false
    var isLocalDevice: Bool = false
    var openPorts: [Int] = []
}

struct PingPacket: Identifiable {
    let id = UUID()
    let seq: Int
    let host: String
    let ip: String
    let bytes: Int
    let ttl: Int
    let rttMs: Double
    let isSuccess: Bool
    var errorMessage: String? = nil
}

struct PingSummary {
    let host: String
    let ip: String
    let packetsSent: Int
    let packetsReceived: Int
    let packetLossPercent: Double
    let minRttMs: Double
    let avgRttMs: Double
    let maxRttMs: Double
    let stdDevRttMs: Double
}

struct TracerouteHop: Identifiable {
    let id = UUID()
    let hopNumber: Int
    let ipAddress: String
    var hostname: String = ""
    let rttMs: Double
    let isSuccessful: Bool
}

enum PortStatus {
    case open
    case closed
    case filtered
}

struct PortScanResult: Identifiable {
    var id: Int { port }
    let port: Int
    let serviceName: String
    let status: PortStatus
    var banner: String = ""
}

struct DnsRecordItem: Identifiable {
    let id = UUID()
    let type: String
    let name: String
    let value: String
    let ttl: Int
    var priority: Int? = nil
}

struct WhoisResult {
    let query: String
    let rawText: String
    var registrar: String = ""
    var creationDate: String = ""
    var expirationDate: String = ""
    var nameServers: [String] = []
}
