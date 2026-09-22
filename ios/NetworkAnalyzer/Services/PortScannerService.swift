import Foundation
import Network

class PortScannerService {
    
    static let commonPorts: [Int: String] = [
        21: "FTP",
        22: "SSH",
        23: "Telnet",
        25: "SMTP",
        53: "DNS",
        80: "HTTP",
        110: "POP3",
        139: "NetBIOS",
        143: "IMAP",
        443: "HTTPS",
        445: "SMB / Microsoft-DS",
        587: "SMTP Submission",
        993: "IMAPS",
        995: "POP3S",
        1433: "MS SQL Server",
        3306: "MySQL",
        3389: "RDP",
        5432: "PostgreSQL",
        5900: "VNC",
        6379: "Redis",
        8080: "HTTP Proxy / Alt",
        8443: "HTTPS Alt",
        27017: "MongoDB"
    ]
    
    private var isCancelled = false
    
    func cancel() {
        isCancelled = true
    }
    
    func scanPorts(
        host: String,
        ports: [Int],
        onProgress: @escaping (Float) -> Void,
        onPortFound: @escaping (PortScanResult) -> Void
    ) async -> [PortScanResult] {
        isCancelled = false
        var openPorts: [PortScanResult] = []
        let total = ports.count
        let batchSize = 20
        var completed = 0
        
        for i in stride(from: 0, to: ports.count, by: batchSize) {
            if isCancelled { break }
            let end = min(i + batchSize, ports.count)
            let chunk = Array(ports[i..<end])
            
            await withTaskGroup(of: PortScanResult?.self) { group in
                for port in chunk {
                    group.addTask {
                        return await self.checkPort(host: host, port: port)
                    }
                }
                
                for await result in group {
                    if let openResult = result {
                        openPorts.append(openResult)
                        onPortFound(openResult)
                    }
                }
            }
            
            completed += chunk.count
            onProgress(Float(completed) / Float(total))
        }
        
        return openPorts.sorted { $0.port < $1.port }
    }
    
    private func checkPort(host: String, port: Int) async -> PortScanResult? {
        let service = PortScannerService.commonPorts[port] ?? "Unknown Service"
        
        return await withCheckedContinuation { continuation in
            let endpoint = NWEndpoint.Host(host)
            guard let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else {
                continuation.resume(returning: nil)
                return
            }
            
            let connection = NWConnection(host: endpoint, port: nwPort, using: .tcp)
            var didResume = false
            
            let finish: (PortScanResult?) -> Void = { result in
                if !didResume {
                    didResume = true
                    connection.cancel()
                    continuation.resume(returning: result)
                }
            }
            
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    finish(PortScanResult(port: port, serviceName: service, status: .open))
                case .failed, .cancelled:
                    finish(nil)
                default:
                    break
                }
            }
            
            connection.start(queue: .global())
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.35) {
                finish(nil)
            }
        }
    }
}
