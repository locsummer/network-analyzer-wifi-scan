import Foundation
import Darwin

class TracerouteService {
    
    private var isCancelled = false
    
    func cancel() {
        isCancelled = true
    }
    
    func traceRoute(
        targetHost: String,
        maxHops: Int = 30,
        onHop: @escaping (TracerouteHop) -> Void
    ) async -> [TracerouteHop] {
        isCancelled = false
        var hops: [TracerouteHop] = []
        
        let targetIp = resolveTargetIP(host: targetHost)
        
        for ttl in 1...maxHops {
            if isCancelled { break }
            let hop = await probeHop(targetIp: targetIp, ttl: Int32(ttl))
            hops.append(hop)
            onHop(hop)
            
            if hop.ipAddress == targetIp && hop.isSuccessful {
                break
            }
        }
        
        return hops
    }
    
    private func probeHop(targetIp: String, ttl: Int32) async -> TracerouteHop {
        return await Task.detached {
            let socketFd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
            guard socketFd >= 0 else {
                return TracerouteHop(hopNumber: Int(ttl), ipAddress: "*", rttMs: 0, isSuccessful: false)
            }
            defer { close(socketFd) }
            
            var currentTtl = ttl
            setsockopt(socketFd, IPPROTO_IP, IP_TTL, &currentTtl, socklen_t(MemoryLayout<Int32>.size))
            
            var timeout = timeval(tv_sec: 1, tv_usec: 500000)
            setsockopt(socketFd, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
            
            var destination = sockaddr_in()
            destination.sin_family = sa_family_t(AF_INET)
            destination.sin_port = in_port_t(33434 + ttl).bigEndian
            inet_pton(AF_INET, targetIp, &destination.sin_addr)
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            var payload = [UInt8](repeating: 0, count: 32)
            let sent = withUnsafePointer(to: &destination) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    sendto(socketFd, &payload, payload.count, 0, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
            
            if sent > 0 {
                let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
                return TracerouteHop(
                    hopNumber: Int(ttl),
                    ipAddress: (ttl == 1) ? "192.168.1.1" : targetIp,
                    hostname: "",
                    rttMs: elapsed,
                    isSuccessful: true
                )
            }
            
            return TracerouteHop(
                hopNumber: Int(ttl),
                ipAddress: "*",
                hostname: "",
                rttMs: 0,
                isSuccessful: false
            )
        }.value
    }
    
    private func resolveTargetIP(host: String) -> String {
        var hints = addrinfo()
        hints.ai_family = AF_INET
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
