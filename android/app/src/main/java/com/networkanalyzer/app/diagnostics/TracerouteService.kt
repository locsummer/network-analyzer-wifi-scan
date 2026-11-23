package com.networkanalyzer.app.diagnostics

import com.networkanalyzer.app.data.TracerouteHop
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.InetAddress
import java.util.concurrent.atomic.AtomicBoolean

class TracerouteService {

    private val isCancelled = AtomicBoolean(false)

    fun cancel() {
        isCancelled.set(true)
    }

    suspend fun traceRoute(
        targetHost: String,
        maxHops: Int = 30,
        onHop: (TracerouteHop) -> Unit
    ): List<TracerouteHop> = withContext(Dispatchers.IO) {
        isCancelled.set(false)
        val hops = mutableListOf<TracerouteHop>()

        val targetIp = try {
            InetAddress.getByName(targetHost).hostAddress ?: targetHost
        } catch (_: Exception) {
            targetHost
        }

        for (ttl in 1..maxHops) {
            if (isCancelled.get()) break

            val hop = probeHop(targetIp, ttl)
            hops.add(hop)
            onHop(hop)

            if (hop.ipAddress == targetIp && hop.isSuccessful) {
                break
            }
        }

        hops
    }

    private fun probeHop(targetIp: String, ttl: Int): TracerouteHop {
        val startTime = System.currentTimeMillis()

        try {
            // Android ping supports -t (or -m) for TTL
            val process = Runtime.getRuntime().exec("ping -c 1 -w 2 -t $ttl $targetIp")
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            var line: String?
            var hopIp: String? = null
            var rtt = 0.0

            while (reader.readLine().also { line = it } != null) {
                val l = line!!.lowercase()

                // Check for "From <ip>: ... Time to live exceeded"
                if (l.contains("time to live exceeded") || l.contains("ttl exceeded") || l.contains("from ")) {
                    val tokens = line!!.split("\\s+".toRegex())
                    for (i in tokens.indices) {
                        if (tokens[i].equals("from", ignoreCase = true) && i + 1 < tokens.size) {
                            hopIp = tokens[i + 1].replace(":", "").trim()
                            break
                        }
                    }
                }

                // Check for normal reply from destination
                if (l.contains("bytes from") && l.contains("time=")) {
                    val tokens = line!!.split("\\s+".toRegex())
                    for (i in tokens.indices) {
                        if (tokens[i].equals("from", ignoreCase = true) && i + 1 < tokens.size) {
                            hopIp = tokens[i + 1].replace(":", "").trim()
                        }
                    }
                    val timeStr = l.substringAfter("time=").substringBefore(" ms").trim()
                    rtt = timeStr.toDoubleOrNull() ?: 0.0
                }
            }
            process.waitFor()

            val elapsed = (System.currentTimeMillis() - startTime).coerceAtLeast(1).toDouble()
            val finalRtt = if (rtt > 0) rtt else elapsed

            if (!hopIp.isNullOrBlank()) {
                var hostname = ""
                try {
                    val resolved = InetAddress.getByName(hopIp).canonicalHostName
                    if (resolved != hopIp) hostname = resolved
                } catch (_: Exception) {}

                return TracerouteHop(
                    hopNumber = ttl,
                    ipAddress = hopIp,
                    hostname = hostname,
                    rttMs = finalRtt,
                    isSuccessful = true
                )
            }
        } catch (_: Exception) {}

        return TracerouteHop(
            hopNumber = ttl,
            ipAddress = "*",
            hostname = "",
            rttMs = 0.0,
            isSuccessful = false
        )
    }
}
