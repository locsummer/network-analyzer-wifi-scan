import Foundation
import Network

class LanScannerService {
    
    private var isCancelled = false
    
    func cancel() {
        isCancelled = true
    }
    
    func scanSubnet(
        localIp: String,
        gatewayIp: String,
        onProgress: @escaping (Float) -> Void,
        onDeviceFound: @escaping (DiscoveredDevice) -> Void
    ) async -> [DiscoveredDevice] {
        isCancelled = false
        var devices: [DiscoveredDevice] = []
        
        guard !localIp.isEmpty, localIp != "-", let lastDotIndex = localIp.lastIndex(of: ".") else {
            return devices
        }
        
        let prefix = String(localIp[..<lastDotIndex])
        let targetIps = (1...254).map { "\(prefix).\($0)" }
        let total = targetIps.count
        
        let batchSize = 25
        var completed = 0
        
        for i in stride(from: 0, to: targetIps.count, by: batchSize) {
            if isCancelled { break }
            let end = min(i + batchSize, targetIps.count)
            let chunk = targetIps[i..<end]
            
            await withTaskGroup(of: DiscoveredDevice?.self) { group in
                for ip in chunk {
                    group.addTask {
                        return await self.probeHost(ip: ip, localIp: localIp, gatewayIp: gatewayIp)
                    }
                }
                
                for await result in group {
                    if let device = result {
                        devices.append(device)
                        onDeviceFound(device)
                    }
                }
            }
            
            completed += chunk.count
            onProgress(Float(completed) / Float(total))
        }
        
        return devices.sorted {
            let a = Int($0.ipAddress.split(separator: ".").last ?? "0") ?? 0
            let b = Int($1.ipAddress.split(separator: ".").last ?? "0") ?? 0
            return a < b
        }
    }
    
    private func probeHost(ip: String, localIp: String, gatewayIp: String) async -> DiscoveredDevice? {
        let isLocal = (ip == localIp)
        let isGateway = (ip == gatewayIp)
        
        if isLocal {
            return DiscoveredDevice(
                ipAddress: ip,
                macAddress: "This iPhone / iPad",
                vendor: "Apple, Inc.",
                hostname: "localhost",
                responseTimeMs: 1,
                isGateway: false,
                isLocalDevice: true
            )
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let isReachable = await checkTCPConnectivity(host: ip, port: 80, timeout: 0.3)
            || await checkTCPConnectivity(host: ip, port: 443, timeout: 0.3)
            || await checkTCPConnectivity(host: ip, port: 445, timeout: 0.3)
            || await checkTCPConnectivity(host: ip, port: 8080, timeout: 0.3)
            || await checkTCPConnectivity(host: ip, port: 5357, timeout: 0.3)
        
        if isReachable || isGateway {
            let rtt = max(1.0, (CFAbsoluteTimeGetCurrent() - startTime) * 1000)
            let hostname = resolveHostname(ip: ip)
            let vendor = isGateway ? "Gateway Router" : "Network Device"
            
            return DiscoveredDevice(
                ipAddress: ip,
                macAddress: "",
                vendor: vendor,
                hostname: hostname,
                responseTimeMs: rtt,
                isGateway: isGateway,
                isLocalDevice: false
            )
        }
        
        return nil
    }
    
    private func checkTCPConnectivity(host: String, port: UInt16, timeout: TimeInterval) async -> Bool {
        return await withCheckedContinuation { continuation in
            let endpoint = NWEndpoint.Host(host)
            let nwPort = NWEndpoint.Port(rawValue: port)!
            let connection = NWConnection(host: endpoint, port: nwPort, using: .tcp)
            
            var didResume = false
            let resumeOnce: (Bool) -> Void = { result in
                if !didResume {
                    didResume = true
                    connection.cancel()
                    continuation.resume(returning: result)
                }
            }
            
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    resumeOnce(true)
                case .failed, .cancelled:
                    resumeOnce(false)
                default:
                    break
                }
            }
            
            connection.start(queue: .global())
            
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                resumeOnce(false)
            }
        }
    }
    
    private func resolveHostname(ip: String) -> String {
        var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        var socketAddress = sockaddr_in()
        socketAddress.sin_family = sa_family_t(AF_INET)
        socketAddress.sin_len = __uint8_t(MemoryLayout<sockaddr_in>.size)
        inet_pton(AF_INET, ip, &socketAddress.sin_addr)
        
        let result = withUnsafePointer(to: &socketAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                getnameinfo($0, socklen_t(MemoryLayout<sockaddr_in>.size), &hostBuffer, socklen_t(hostBuffer.count), nil, 0, 0)
            }
        }
        
        if result == 0 {
            let name = String(cString: hostBuffer)
            return name == ip ? "" : name
        }
        return ""
    }
}
