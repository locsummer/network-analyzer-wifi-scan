package com.networkanalyzer.app.data

enum class ConnectionType(val label: String) {
    WIFI("Wi-Fi"),
    CELLULAR("Cellular"),
    ETHERNET("Ethernet"),
    NONE("Disconnected")
}

data class NetworkSummary(
    val connectionType: ConnectionType = ConnectionType.NONE,
    val interfaceName: String = "-",
    val isConnected: Boolean = false,
    val wifiSsid: String = "-",
    val wifiBssid: String = "-",
    val localIpv4: String = "-",
    val localIpv6: String = "-",
    val subnetMask: String = "255.255.255.0",
    val defaultGateway: String = "-",
    val broadcastIp: String = "-",
    val macAddress: String = "-",
    val dnsServers: List<String> = emptyList(),
    val publicIp: String = "-",
    val ispName: String = "-",
    val location: String = "-"
)

data class DiscoveredDevice(
    val ipAddress: String,
    val macAddress: String = "",
    val vendor: String = "Network Device",
    val hostname: String = "",
    val responseTimeMs: Double = 0.0,
    val isGateway: Boolean = false,
    val isLocalDevice: Boolean = false,
    val openPorts: List<Int> = emptyList()
)

data class WifiScanItem(
    val ssid: String,
    val bssid: String,
    val capabilities: String,
    val levelDbm: Int,
    val frequencyMhz: Int,
    val channel: Int,
    val band: String
)

data class PingPacket(
    val seq: Int,
    val host: String,
    val ip: String,
    val bytes: Int = 64,
    val ttl: Int = 64,
    val rttMs: Double,
    val isSuccess: Boolean,
    val errorMessage: String? = null
)

data class PingSummary(
    val host: String,
    val ip: String,
    val packetsSent: Int,
    val packetsReceived: Int,
    val packetLossPercent: Double,
    val minRttMs: Double,
    val avgRttMs: Double,
    val maxRttMs: Double,
    val stdDevRttMs: Double
)

data class TracerouteHop(
    val hopNumber: Int,
    val ipAddress: String,
    val hostname: String = "",
    val rttMs: Double,
    val isSuccessful: Boolean
)

enum class PortStatus {
    OPEN,
    CLOSED,
    FILTERED
}

data class PortScanResult(
    val port: Int,
    val serviceName: String,
    val status: PortStatus = PortStatus.OPEN,
    val banner: String = ""
)

data class DnsRecordItem(
    val type: String,
    val name: String,
    val value: String,
    val ttl: Int = 300,
    val priority: Int? = null
)

data class WhoisResult(
    val query: String,
    val rawText: String = "",
    val registrar: String = "",
    val creationDate: String = "",
    val expirationDate: String = "",
    val nameServers: List<String> = emptyList()
)
