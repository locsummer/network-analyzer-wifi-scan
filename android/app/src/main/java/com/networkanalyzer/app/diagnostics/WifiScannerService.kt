package com.networkanalyzer.app.diagnostics

import android.content.Context
import android.net.wifi.ScanResult
import android.net.wifi.WifiManager
import com.networkanalyzer.app.data.WifiScanItem
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class WifiScannerService(private val context: Context) {

    suspend fun scanWifiNetworks(): List<WifiScanItem> = withContext(Dispatchers.IO) {
        val wm = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
            ?: return@withContext emptyList()

        try {
            @Suppress("DEPRECATION")
            wm.startScan()
        } catch (_: Exception) {}

        @Suppress("DEPRECATION")
        val results: List<ScanResult> = try {
            wm.scanResults ?: emptyList()
        } catch (_: Exception) {
            emptyList()
        }

        results.map { scan ->
            val ssid = scan.SSID?.replace("\"", "").orEmpty().ifEmpty { "[Hidden Network]" }
            val bssid = scan.BSSID ?: "-"
            val freq = scan.frequency
            val channel = frequencyToChannel(freq)
            val band = when {
                freq in 2400..2495 -> "2.4 GHz"
                freq in 5000..5900 -> "5 GHz"
                freq > 5900 -> "6 GHz"
                else -> "Unknown"
            }

            WifiScanItem(
                ssid = ssid,
                bssid = bssid,
                capabilities = parseCapabilities(scan.capabilities),
                levelDbm = scan.level,
                frequencyMhz = freq,
                channel = channel,
                band = band
            )
        }.sortedByDescending { it.levelDbm }
    }

    private fun frequencyToChannel(freq: Int): Int {
        return when {
            freq == 2484 -> 14
            freq in 2412..2472 -> (freq - 2412) / 5 + 1
            freq in 5170..5825 -> (freq - 5170) / 5 + 34
            freq in 5945..7105 -> (freq - 5945) / 5 + 1
            else -> 0
        }
    }

    private fun parseCapabilities(cap: String?): String {
        if (cap.isNullOrBlank()) return "Open"
        val builder = mutableListOf<String>()
        if (cap.contains("WPA3")) builder.add("WPA3")
        if (cap.contains("WPA2")) builder.add("WPA2")
        if (cap.contains("WPA-") && !builder.contains("WPA2") && !builder.contains("WPA3")) builder.add("WPA")
        if (cap.contains("WEP")) builder.add("WEP")
        if (cap.contains("WPS")) builder.add("WPS")
        if (builder.isEmpty()) return if (cap.contains("ESS")) "Open" else cap
        return builder.joinToString(" / ")
    }
}
