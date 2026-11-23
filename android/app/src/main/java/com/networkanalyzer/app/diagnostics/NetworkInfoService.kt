package com.networkanalyzer.app.diagnostics

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import com.networkanalyzer.app.data.ConnectionType
import com.networkanalyzer.app.data.NetworkSummary
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.Inet4Address
import java.net.Inet6Address
import java.net.NetworkInterface
import java.net.URL

class NetworkInfoService(private val context: Context) {

    suspend fun fetchNetworkSummary(): NetworkSummary = withContext(Dispatchers.IO) {
        var summary = NetworkSummary()
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
        val wm = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager

        val activeNetwork = cm?.activeNetwork
        val caps = cm?.getNetworkCapabilities(activeNetwork)
        val linkProps = cm?.getLinkProperties(activeNetwork)

        var connType = ConnectionType.NONE
        var isConn = false

        if (caps != null) {
            when {
                caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> {
                    connType = ConnectionType.WIFI
                    isConn = true
                }
                caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> {
                    connType = ConnectionType.CELLULAR
                    isConn = true
                }
                caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> {
                    connType = ConnectionType.ETHERNET
                    isConn = true
                }
            }
        }

        // 1. IP & Interface Details
        var localIpv4 = "-"
        var localIpv6 = "-"
        var interfaceName = linkProps?.interfaceName ?: "-"
        var gateway = "-"
        var broadcast = "-"
        var netmask = "255.255.255.0"

        try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val nif = interfaces.nextElement()
                if (nif.isLoopback || !nif.isUp) continue
                if (interfaceName != "-" && nif.name != interfaceName && !nif.name.startsWith("wlan") && !nif.name.startsWith("eth") && !nif.name.startsWith("rmnet")) {
                    continue
                }

                for (addr in nif.interfaceAddresses) {
                    val inet = addr.address
                    if (inet is Inet4Address && !inet.isLoopbackAddress) {
                        localIpv4 = inet.hostAddress ?: "-"
                        interfaceName = nif.name
                        val prefix = addr.networkPrefixLength
                        netmask = prefixLengthToSubnetMask(prefix)
                        val parts = localIpv4.split(".")
                        if (parts.size == 4) {
                            gateway = "${parts[0]}.${parts[1]}.${parts[2]}.1"
                            broadcast = "${parts[0]}.${parts[1]}.${parts[2]}.255"
                        }
                    } else if (inet is Inet6Address && !inet.isLoopbackAddress && localIpv6 == "-") {
                        val host = inet.hostAddress ?: ""
                        localIpv6 = host.substringBefore('%')
                    }
                }
                if (localIpv4 != "-") break
            }
        } catch (_: Exception) {}

        // Gateways from LinkProperties if available
        linkProps?.routes?.firstOrNull { it.isDefaultRoute && it.gateway != null }?.let {
            gateway = it.gateway?.hostAddress ?: gateway
        }

        // DNS Servers
        val dnsList = linkProps?.dnsServers?.mapNotNull { it.hostAddress } ?: emptyList()

        // 2. Wi-Fi Details
        var wifiSsid = "-"
        var wifiBssid = "-"
        if (connType == ConnectionType.WIFI && wm != null) {
            val info = wm.connectionInfo
            if (info != null) {
                val ssid = info.ssid?.replace("\"", "") ?: "-"
                wifiSsid = if (ssid == "<unknown ssid>") "Connected Wi-Fi" else ssid
                wifiBssid = info.bssid ?: "-"
            }
        }

        summary = summary.copy(
            connectionType = connType,
            interfaceName = interfaceName,
            isConnected = isConn,
            wifiSsid = wifiSsid,
            wifiBssid = wifiBssid,
            localIpv4 = localIpv4,
            localIpv6 = localIpv6,
            subnetMask = netmask,
            defaultGateway = gateway,
            broadcastIp = broadcast,
            dnsServers = dnsList
        )

        // 3. Public IP & Location (via public IP service)
        try {
            val url = URL("https://ipwhois.app/json/")
            val conn = url.openConnection() as HttpURLConnection
            conn.connectTimeout = 4000
            conn.readTimeout = 4000
            if (conn.responseCode == 200) {
                val reader = BufferedReader(InputStreamReader(conn.inputStream))
                val response = reader.readText()
                reader.close()
                val json = JSONObject(response)
                val pubIp = json.optString("ip", "-")
                val isp = json.optString("isp", "-")
                val city = json.optString("city", "")
                val country = json.optString("country", "")
                val loc = if (city.isNotEmpty()) "$city, $country" else country

                summary = summary.copy(
                    publicIp = pubIp,
                    ispName = isp,
                    location = if (loc.isNotEmpty()) loc else "-"
                )
            }
        } catch (_: Exception) {}

        summary
    }

    private fun prefixLengthToSubnetMask(prefix: Short): String {
        var shift = (0xffffffffL shl (32 - prefix)).toInt()
        return "${(shift ushr 24) and 0xff}.${(shift ushr 16) and 0xff}.${(shift ushr 8) and 0xff}.${shift and 0xff}"
    }
}
