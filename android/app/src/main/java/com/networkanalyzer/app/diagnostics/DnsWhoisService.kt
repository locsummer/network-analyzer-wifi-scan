package com.networkanalyzer.app.diagnostics

import com.networkanalyzer.app.data.DnsRecordItem
import com.networkanalyzer.app.data.WhoisResult
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.io.PrintWriter
import java.net.Inet4Address
import java.net.Inet6Address
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Socket

class DnsWhoisService {

    suspend fun queryDns(domain: String): List<DnsRecordItem> = withContext(Dispatchers.IO) {
        val records = mutableListOf<DnsRecordItem>()
        val clean = domain.trim()
            .removePrefix("https://")
            .removePrefix("http://")
            .substringBefore("/")

        try {
            val addresses = InetAddress.getAllByName(clean)
            for (addr in addresses) {
                if (addr is Inet4Address) {
                    val ip = addr.hostAddress ?: continue
                    if (records.none { it.value == ip }) {
                        records.add(DnsRecordItem(type = "A", name = clean, value = ip, ttl = 300))
                    }
                } else if (addr is Inet6Address) {
                    val ip = addr.hostAddress ?: continue
                    if (records.none { it.value == ip }) {
                        records.add(DnsRecordItem(type = "AAAA", name = clean, value = ip, ttl = 300))
                    }
                }
            }
        } catch (_: Exception) {}

        records
    }

    suspend fun queryWhois(query: String): WhoisResult = withContext(Dispatchers.IO) {
        val clean = query.trim()
            .removePrefix("https://")
            .removePrefix("http://")
            .substringBefore("/")

        val server = determineWhoisServer(clean)
        val raw = executeWhoisSocket(server, clean)

        var registrar = ""
        var creationDate = ""
        var expirationDate = ""
        val nameServers = mutableListOf<String>()

        raw.lines().forEach { line ->
            val l = line.trim()
            val lower = l.lowercase()
            when {
                lower.startsWith("registrar:") -> {
                    registrar = l.substringAfter(":").trim()
                }
                lower.startsWith("creation date:") || lower.startsWith("created:") -> {
                    creationDate = l.substringAfter(":").trim()
                }
                lower.startsWith("registry expiry date:") || lower.startsWith("expiration date:") -> {
                    expirationDate = l.substringAfter(":").trim()
                }
                lower.startsWith("name server:") || lower.startsWith("nserver:") -> {
                    val ns = l.substringAfter(":").trim().lowercase()
                    if (ns.isNotBlank() && !nameServers.contains(ns)) {
                        nameServers.add(ns)
                    }
                }
            }
        }

        WhoisResult(
            query = clean,
            rawText = raw,
            registrar = registrar,
            creationDate = creationDate,
            expirationDate = expirationDate,
            nameServers = nameServers
        )
    }

    private fun determineWhoisServer(domain: String): String {
        return when {
            domain.matches(Regex("^\\d+\\.\\d+\\.\\d+\\.\\d+$")) -> "whois.arin.net"
            domain.endsWith(".com") || domain.endsWith(".net") -> "whois.verisign-grs.com"
            domain.endsWith(".org") -> "whois.pir.org"
            domain.endsWith(".io") -> "whois.nic.io"
            else -> "whois.iana.org"
        }
    }

    private fun executeWhoisSocket(server: String, query: String): String {
        return try {
            Socket().use { socket ->
                socket.soTimeout = 5000
                socket.connect(InetSocketAddress(server, 43), 5000)

                val out = PrintWriter(OutputStreamWriter(socket.getOutputStream(), "UTF-8"), true)
                out.println(query)

                val reader = BufferedReader(InputStreamReader(socket.getInputStream(), "UTF-8"))
                val sb = StringBuilder()
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    sb.append(line).append("\n")
                }
                sb.toString()
            }
        } catch (e: Exception) {
            "WHOIS query failed: ${e.message}"
        }
    }
}
