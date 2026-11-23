package com.networkanalyzer.app.diagnostics

import com.networkanalyzer.app.data.PingPacket
import com.networkanalyzer.app.data.PingSummary
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Socket
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.pow
import kotlin.math.sqrt

class PingService {

    private val isCancelled = AtomicBoolean(false)

    fun cancel() {
        isCancelled.set(true)
    }

    suspend fun runPing(
        host: String,
        count: Int = 10,
        onPacket: (PingPacket) -> Unit
    ): PingSummary = withContext(Dispatchers.IO) {
        isCancelled.set(false)
        val rtts = mutableListOf<Double>()
        var receivedCount = 0

        val resolvedIp = try {
            InetAddress.getByName(host).hostAddress ?: host
        } catch (_: Exception) {
            host
        }

        for (seq in 1..count) {
            if (isCancelled.get()) break

            val packet = pingSingle(host, resolvedIp, seq)
            if (packet.isSuccess) {
                receivedCount++
                rtts.add(packet.rttMs)
            }
            onPacket(packet)

            if (seq < count && !isCancelled.get()) {
                delay(600)
            }
        }

        val lossPercent = if (count > 0) ((count - receivedCount).toDouble() / count.toDouble()) * 100.0 else 0.0
        val minRtt = rtts.minOrNull() ?: 0.0
        val avgRtt = if (rtts.isNotEmpty()) rtts.average() else 0.0
        val maxRtt = rtts.maxOrNull() ?: 0.0

        val stdDev = if (rtts.isNotEmpty()) {
            val variance = rtts.map { (it - avgRtt).pow(2.0) }.average()
            sqrt(variance)
        } else {
            0.0
        }

        PingSummary(
            host = host,
            ip = resolvedIp,
            packetsSent = count,
            packetsReceived = receivedCount,
            packetLossPercent = lossPercent,
            minRttMs = minRtt,
            avgRttMs = avgRtt,
            maxRttMs = maxRtt,
            stdDevRttMs = stdDev
        )
    }

    private fun pingSingle(host: String, ip: String, seq: Int): PingPacket {
        val startTime = System.nanoTime()

        // 1. Try ICMP ping command
        try {
            val process = Runtime.getRuntime().exec("ping -c 1 -W 1 $ip")
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            var line: String?
            var rtt = -1.0
            var ttl = 64

            while (reader.readLine().also { line = it } != null) {
                val l = line!!.lowercase()
                if (l.contains("time=")) {
                    val timeStr = l.substringAfter("time=").substringBefore(" ms").trim()
                    rtt = timeStr.toDoubleOrNull() ?: -1.0
                }
                if (l.contains("ttl=")) {
                    val ttlStr = l.substringAfter("ttl=").substringBefore(" ").trim()
                    ttl = ttlStr.toIntOrNull() ?: 64
                }
            }
            process.waitFor()

            if (rtt >= 0) {
                return PingPacket(
                    seq = seq,
                    host = host,
                    ip = ip,
                    bytes = 64,
                    ttl = ttl,
                    rttMs = rtt,
                    isSuccess = true
                )
            }
        } catch (_: Exception) {}

        // 2. Fallback to TCP Socket probe
        val socketStart = System.nanoTime()
        return try {
            Socket().use { socket ->
                socket.connect(InetSocketAddress(ip, 443), 1500)
            }
            val elapsed = (System.nanoTime() - socketStart) / 1_000_000.0
            PingPacket(
                seq = seq,
                host = host,
                ip = ip,
                bytes = 64,
                ttl = 64,
                rttMs = elapsed,
                isSuccess = true
            )
        } catch (e: Exception) {
            val elapsed = (System.nanoTime() - startTime) / 1_000_000.0
            PingPacket(
                seq = seq,
                host = host,
                ip = ip,
                bytes = 64,
                ttl = 64,
                rttMs = elapsed,
                isSuccess = false,
                errorMessage = e.message ?: "Request timeout"
            )
        }
    }
}
