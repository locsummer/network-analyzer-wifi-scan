package com.networkanalyzer.app.diagnostics

import com.networkanalyzer.app.data.DiscoveredDevice
import com.networkanalyzer.app.data.MacVendorLookup
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.File
import java.io.FileReader
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Socket
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger

class LanScannerService {

    private val isCancelled = AtomicBoolean(false)

    fun cancel() {
        isCancelled.set(true)
    }

    suspend fun scanSubnet(
        localIp: String,
        gatewayIp: String,
        onProgress: (Float) -> Unit,
        onDeviceFound: (DiscoveredDevice) -> Unit
    ): List<DiscoveredDevice> = withContext(Dispatchers.IO) {
        isCancelled.set(false)
        val devices = mutableListOf<DiscoveredDevice>()

        if (localIp.isBlank() || localIp == "-" || !localIp.contains(".")) {
            return@withContext devices
        }

        val prefix = localIp.substringBeforeLast(".")
        val targetIps = (1..254).map { "$prefix.$it" }
        val total = targetIps.size
        val completedCount = AtomicInteger(0)

        // Read ARP table first (or continually)
        val arpMap = readArpTable()

        // Batch scan in chunks of 25 to avoid overwhelming sockets
        val chunkSize = 25
        for (chunk in targetIps.chunked(chunkSize)) {
            if (isCancelled.get()) break

            val results = coroutineScope {
                chunk.map { ip ->
                    async {
                        val dev = probeHost(ip, localIp, gatewayIp, arpMap[ip])
                        val done = completedCount.incrementAndGet()
                        onProgress(done.toFloat() / total.toFloat())
                        dev
                    }
                }.awaitAll().filterNotNull()
            }

            for (device in results) {
                devices.add(device)
                onDeviceFound(device)
            }
        }

        // Re-read ARP table after scan because network probes fill the ARP cache!
        val updatedArp = readArpTable()
        devices.map { dev ->
            val mac = updatedArp[dev.ipAddress] ?: dev.macAddress
            if (mac.isNotBlank() && dev.vendor == "Network Device") {
                dev.copy(macAddress = mac, vendor = MacVendorLookup.lookup(mac))
            } else {
                dev
            }
        }.sortedBy { dev ->
            dev.ipAddress.substringAfterLast(".").toIntOrNull() ?: 0
        }
    }

    private fun probeHost(
        ip: String,
        localIp: String,
        gatewayIp: String,
        knownMac: String?
    ): DiscoveredDevice? {
        val isLocal = (ip == localIp)
        val isGateway = (ip == gatewayIp)

        if (isLocal) {
            return DiscoveredDevice(
                ipAddress = ip,
                macAddress = "This Android Device",
                vendor = "Android Device",
                hostname = "localhost",
                responseTimeMs = 1.0,
                isGateway = false,
                isLocalDevice = true
            )
        }

        val startTime = System.currentTimeMillis()
        var reachable = false
        val probePorts = intArrayOf(80, 443, 445, 8080, 5357, 22)

        for (port in probePorts) {
            if (isCancelled.get()) return null
            try {
                Socket().use { socket ->
                    socket.connect(InetSocketAddress(ip, port), 250)
                    reachable = true
                }
                break
            } catch (_: Exception) {}
        }

        // If not reachable by TCP, try ping check
        if (!reachable) {
            try {
                val inet = InetAddress.getByName(ip)
                if (inet.isReachable(250)) {
                    reachable = true
                }
            } catch (_: Exception) {}
        }

        if (reachable || isGateway || knownMac != null) {
            val rtt = (System.currentTimeMillis() - startTime).coerceAtLeast(1).toDouble()
            var hostname = ""
            try {
                val host = InetAddress.getByName(ip).canonicalHostName
                if (host != ip) hostname = host
            } catch (_: Exception) {}

            val mac = knownMac ?: ""
            val vendor = when {
                isGateway -> "Gateway Router"
                mac.isNotBlank() -> MacVendorLookup.lookup(mac)
                else -> "Network Device"
            }

            return DiscoveredDevice(
                ipAddress = ip,
                macAddress = mac,
                vendor = vendor,
                hostname = hostname,
                responseTimeMs = rtt,
                isGateway = isGateway,
                isLocalDevice = false
            )
        }

        return null
    }

    private fun readArpTable(): Map<String, String> {
        val arpMap = mutableMapOf<String, String>()
        try {
            val file = File("/proc/net/arp")
            if (file.exists()) {
                BufferedReader(FileReader(file)).use { br ->
                    var line: String? = br.readLine() // Skip header
                    while (br.readLine().also { line = it } != null) {
                        val tokens = line!!.split("\\s+".toRegex())
                        if (tokens.size >= 4) {
                            val ip = tokens[0]
                            val mac = tokens[3]
                            if (mac != "00:00:00:00:00:00") {
                                arpMap[ip] = mac
                            }
                        }
                    }
                }
            }
        } catch (_: Exception) {}
        return arpMap
    }
}
