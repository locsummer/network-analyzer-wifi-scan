import Foundation
import Network
import Darwin

class PingService {
    
    private var isCancelled = false
    
    func cancel() {
        isCancelled = true
    }
    
    func runPing(
        host: String,
        count: Int = 10,
        onPacket: @escaping (PingPacket) -> Void
    ) async -> PingSummary {
        isCancelled = false
        var rtts: [Double] = []
        var receivedCount = 0
        let resolvedIp = resolveIP(host: host)
        
        for seq in 1...count {
            if isCancelled { break }
            let packet = await pingSingle(host: host, ip: resolvedIp, seq: seq)
            if packet.isSuccess {
                receivedCount += 1
                rtts.append(packet.rttMs)
            }
            onPacket(packet)
            
            if seq < count && !isCancelled {
                try? await Task.sleep(nanoseconds: 600_000_000) // 600ms interval
            }
        }
        
        let lossPercent = Double(count - receivedCount) / Double(count) * 100.0
        let minRtt = rtts.min() ?? 0.0
        let avgRtt = rtts.isEmpty ? 0.0 : rtts.reduce(0, +) / Double(rtts.count)
        let maxRtt = rtts.max() ?? 0.0
        
        let stdDev: Double
        if !rtts.isEmpty {
            let variance = rtts.map { pow($0 - avgRtt, 2) }.reduce(0, +) / Double(rtts.count)
            stdDev = sqrt(variance)
        } else {
            stdDev = 0.0
        }
        
        return PingSummary(
            host: host,
            ip: resolvedIp,
            packetsSent: count,
            packetsReceived: receivedCount,
            packetLossPercent: lossPercent,
            minRttMs: minRtt,
            avgRttMs: avgRtt,
            maxRttMs: maxRtt,
            stdDevRttMs: stdDev
        )
    }
    
    private func pingSingle(host: String, ip: String, seq: Int) async -> PingPacket {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        return await withCheckedContinuation { continuation in
            let endpoint = NWEndpoint.Host(ip)
            // Try port 443 (HTTPS) or 80 (HTTP)
            let nwPort = NWEndpoint.Port(rawValue: 443)!
            let connection = NWConnection(host: endpoint, port: nwPort, using: .tcp)
            
            var didResume = false
            let finish: (Bool, String?) -> Void = { success, error in
                if !didResume {
                    didResume = true
                    connection.cancel()
                    let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
                    let packet = PingPacket(
                        seq: seq,
                        host: host,
                        ip: ip,
                        bytes: 64,
                        ttl: 64,
                        rttMs: elapsed,
                        isSuccess: success,
                        errorMessage: error
                    )
                    continuation.resume(returning: packet)
                }
            }
            
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    finish(true, nil)
                case .failed(let err):
                    finish(false, err.localizedDescription)
                case .cancelled:
                    finish(false, "Cancelled")
                default:
                    break
                }
            }
            
            connection.start(queue: .global())
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                finish(false, "Request timeout")
            }
        }
    }
    
    private func resolveIP(host: String) -> String {
        var hints = addrinfo()
        hints.ai_family = AF_INET
        hints.ai_socktype = SOCK_STREAM
        
        var res: UnsafeMutablePointer<addrinfo>?
        if getaddrinfo(host, nil, &hints, &res) == 0, let first = res {
            defer { freeaddrinfo(res) }
            var ipBuf = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
            let sockAddr = first.pointee.ai_addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
            var addr = sockAddr.sin_addr
            if inet_ntop(AF_INET, &addr, &ipBuf, socklen_t(INET_ADDRSTRLEN)) != nil {
                return String(cString: ipBuf)
            }
        }
        return host
    }
}
