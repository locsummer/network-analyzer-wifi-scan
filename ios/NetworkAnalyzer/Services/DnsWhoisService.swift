import Foundation
import Network

class DnsWhoisService {
    
    func queryDns(domain: String) async -> [DnsRecordItem] {
        var records: [DnsRecordItem] = []
        let clean = domain.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .components(separatedBy: "/").first ?? domain
        
        var hints = addrinfo()
        hints.ai_family = AF_UNSPEC
        hints.ai_socktype = SOCK_STREAM
        
        var res: UnsafeMutablePointer<addrinfo>?
        if getaddrinfo(clean, nil, &hints, &res) == 0, let first = res {
            defer { freeaddrinfo(res) }
            for ptr in sequence(first: first, next: { $0.pointee.ai_next }) {
                let addr = ptr.pointee
                if addr.ai_family == AF_INET {
                    var ipBuf = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                    let sockAddr = addr.ai_addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
                    var sinAddr = sockAddr.sin_addr
                    if inet_ntop(AF_INET, &sinAddr, &ipBuf, socklen_t(INET_ADDRSTRLEN)) != nil {
                        let ip = String(cString: ipBuf)
                        if !records.contains(where: { $0.value == ip }) {
                            records.append(DnsRecordItem(type: "A", name: clean, value: ip, ttl: 300))
                        }
                    }
                } else if addr.ai_family == AF_INET6 {
                    var ipBuf = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
                    let sockAddr = addr.ai_addr.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { $0.pointee }
                    var sinAddr = sockAddr.sin6_addr
                    if inet_ntop(AF_INET6, &sinAddr, &ipBuf, socklen_t(INET6_ADDRSTRLEN)) != nil {
                        let ip = String(cString: ipBuf)
                        if !records.contains(where: { $0.value == ip }) {
                            records.append(DnsRecordItem(type: "AAAA", name: clean, value: ip, ttl: 300))
                        }
                    }
                }
            }
        }
        
        return records
    }
    
    func queryWhois(query: String) async -> WhoisResult {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .components(separatedBy: "/").first ?? query
        
        let server = determineWhoisServer(domain: clean)
        let raw = await executeWhoisSocket(server: server, query: clean)
        
        var registrar = ""
        var creationDate = ""
        var expirationDate = ""
        var nameServers: [String] = []
        
        for line in raw.components(separatedBy: .newlines) {
            let l = line.trimmingCharacters(in: .whitespaces)
            let lower = l.lowercased()
            if lower.starts(with: "registrar:") {
                registrar = l.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
            } else if lower.starts(with: "creation date:") || lower.starts(with: "created:") {
                creationDate = l.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
            } else if lower.starts(with: "registry expiry date:") || lower.starts(with: "expiration date:") {
                expirationDate = l.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
            } else if lower.starts(with: "name server:") || lower.starts(with: "nserver:") {
                let ns = l.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces).lowercased()
                if !ns.isEmpty && !nameServers.contains(ns) {
                    nameServers.append(ns)
                }
            }
        }
        
        return WhoisResult(
            query: clean,
            rawText: raw,
            registrar: registrar,
            creationDate: creationDate,
            expirationDate: expirationDate,
            nameServers: nameServers
        )
    }
    
    private func determineWhoisServer(domain: String) -> String {
        if domain.range(of: "^\\d+\\.\\d+\\.\\d+\\.\\d+$", options: .regularExpression) != nil {
            return "whois.arin.net"
        }
        if domain.hasSuffix(".com") || domain.hasSuffix(".net") {
            return "whois.verisign-grs.com"
        }
        if domain.hasSuffix(".org") {
            return "whois.pir.org"
        }
        return "whois.iana.org"
    }
    
    private func executeWhoisSocket(server: String, query: String) async -> String {
        return await Task.detached {
            let socketFd = socket(AF_INET, SOCK_STREAM, 0)
            guard socketFd >= 0 else { return "Unable to open socket for WHOIS" }
            defer { close(socketFd) }
            
            var timeout = timeval(tv_sec: 5, tv_usec: 0)
            setsockopt(socketFd, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
            setsockopt(socketFd, SOL_SOCKET, SO_SNDTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
            
            var hints = addrinfo()
            hints.ai_family = AF_INET
            hints.ai_socktype = SOCK_STREAM
            var res: UnsafeMutablePointer<addrinfo>?
            guard getaddrinfo(server, "43", &hints, &res) == 0, let first = res else {
                return "Failed to resolve WHOIS server \(server)"
            }
            defer { freeaddrinfo(res) }
            
            guard connect(socketFd, first.pointee.ai_addr, first.pointee.ai_addrlen) == 0 else {
                return "Failed to connect to WHOIS server \(server)"
            }
            
            let queryMessage = "\(query)\r\n"
            guard let data = queryMessage.data(using: .utf8) else { return "" }
            _ = data.withUnsafeBytes { send(socketFd, $0.baseAddress, data.count, 0) }
            
            var responseData = Data()
            var buffer = [UInt8](repeating: 0, count: 1024)
            while true {
                let bytesRead = recv(socketFd, &buffer, buffer.count, 0)
                if bytesRead <= 0 { break }
                responseData.append(buffer, count: bytesRead)
            }
            
            return String(data: responseData, encoding: .utf8) ?? String(data: responseData, encoding: .ascii) ?? "No readable WHOIS output"
        }.value
    }
}
