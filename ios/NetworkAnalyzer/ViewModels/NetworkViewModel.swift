import Foundation
import Combine

@MainActor
class NetworkViewModel: ObservableObject {
    
    // Services
    private let infoService = NetworkInfoService()
    private let lanScannerService = LanScannerService()
    private let pingService = PingService()
    private let tracerouteService = TracerouteService()
    private let portScannerService = PortScannerService()
    private let dnsWhoisService = DnsWhoisService()
    
    // Published States
    @Published var networkSummary = NetworkSummary()
    @Published var isRefreshingInfo = false
    
    // LAN Scanner
    @Published var lanDevices: [DiscoveredDevice] = []
    @Published var isScanningLan = false
    @Published var lanScanProgress: Float = 0
    
    // Ping
    @Published var pingPackets: [PingPacket] = []
    @Published var pingSummary: PingSummary? = nil
    @Published var isPinging = false
    
    // Traceroute
    @Published var tracerouteHops: [TracerouteHop] = []
    @Published var isTracing = false
    
    // Port Scanner
    @Published var openPorts: [PortScanResult] = []
    @Published var isScanningPorts = false
    @Published var portScanProgress: Float = 0
    
    // DNS & Whois
    @Published var dnsRecords: [DnsRecordItem] = []
    @Published var whoisResult: WhoisResult? = nil
    @Published var isQueryingDnsWhois = false
    
    init() {
        refreshNetworkInfo()
    }
    
    func refreshNetworkInfo() {
        guard !isRefreshingInfo else { return }
        isRefreshingInfo = true
        
        Task {
            let summary = await infoService.fetchNetworkSummary()
            self.networkSummary = summary
            self.isRefreshingInfo = false
        }
    }
    
    // LAN Scanner
    func startLanScan() {
        guard !isScanningLan else { return }
        isScanningLan = true
        lanDevices = []
        lanScanProgress = 0
        
        Task {
            let devices = await lanScannerService.scanSubnet(
                localIp: networkSummary.localIpv4,
                gatewayIp: networkSummary.defaultGateway,
                onProgress: { [weak self] progress in
                    Task { @MainActor in self?.lanScanProgress = progress }
                },
                onDeviceFound: { [weak self] device in
                    Task { @MainActor in
                        if !(self?.lanDevices.contains(where: { $0.ipAddress == device.ipAddress }) ?? false) {
                            self?.lanDevices.append(device)
                        }
                    }
                }
            )
            self.lanDevices = devices
            self.isScanningLan = false
            self.lanScanProgress = 1.0
        }
    }
    
    func stopLanScan() {
        lanScannerService.cancel()
        isScanningLan = false
    }
    
    // Ping
    func startPing(host: String, count: Int = 10) {
        guard !isPinging, !host.isEmpty else { return }
        isPinging = true
        pingPackets = []
        pingSummary = nil
        
        Task {
            let summary = await pingService.runPing(host: host, count: count) { [weak self] packet in
                Task { @MainActor in self?.pingPackets.append(packet) }
            }
            self.pingSummary = summary
            self.isPinging = false
        }
    }
    
    func stopPing() {
        pingService.cancel()
        isPinging = false
    }
    
    // Traceroute
    func startTraceroute(host: String) {
        guard !isTracing, !host.isEmpty else { return }
        isTracing = true
        tracerouteHops = []
        
        Task {
            let hops = await tracerouteService.traceRoute(targetHost: host) { [weak self] hop in
                Task { @MainActor in self?.tracerouteHops.append(hop) }
            }
            self.tracerouteHops = hops
            self.isTracing = false
        }
    }
    
    func stopTraceroute() {
        tracerouteService.cancel()
        isTracing = false
    }
    
    // Port Scanner
    func startPortScan(host: String, ports: [Int]) {
        guard !isScanningPorts, !host.isEmpty, !ports.isEmpty else { return }
        isScanningPorts = true
        openPorts = []
        portScanProgress = 0
        
        Task {
            let results = await portScannerService.scanPorts(
                host: host,
                ports: ports,
                onProgress: { [weak self] progress in
                    Task { @MainActor in self?.portScanProgress = progress }
                },
                onPortFound: { [weak self] port in
                    Task { @MainActor in self?.openPorts.append(port) }
                }
            )
            self.openPorts = results
            self.isScanningPorts = false
            self.portScanProgress = 1.0
        }
    }
    
    func stopPortScan() {
        portScannerService.cancel()
        isScanningPorts = false
    }
    
    // DNS & Whois
    func queryDnsAndWhois(query: String) {
        guard !query.isEmpty else { return }
        isQueryingDnsWhois = true
        dnsRecords = []
        whoisResult = nil
        
        Task {
            let records = await dnsWhoisService.queryDns(domain: query)
            let whois = await dnsWhoisService.queryWhois(query: query)
            self.dnsRecords = records
            self.whoisResult = whois
            self.isQueryingDnsWhois = false
        }
    }
}
