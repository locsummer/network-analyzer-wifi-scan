package com.networkanalyzer.app.diagnostics

import com.networkanalyzer.app.data.PortScanResult
import com.networkanalyzer.app.data.PortStatus
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.InetSocketAddress
import java.net.Socket
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger

class PortScannerService {

    companion object {
        val commonPorts = mapOf(
            21 to "FTP",
            22 to "SSH",
            23 to "Telnet",
            25 to "SMTP",
            53 to "DNS",
            80 to "HTTP",
            110 to "POP3",
            139 to "NetBIOS",
            143 to "IMAP",
            443 to "HTTPS",
            445 to "SMB / Microsoft-DS",
            587 to "SMTP Submission",
            993 to "IMAPS",
            995 to "POP3S",
            1433 to "MS SQL Server",
            3306 to "MySQL",
            3389 to "RDP",
            5432 to "PostgreSQL",
            5900 to "VNC",
            6379 to "Redis",
            8080 to "HTTP Proxy / Alt",
            8443 to "HTTPS Alt",
            27017 to "MongoDB"
        )
    }

    private val isCancelled = AtomicBoolean(false)

    fun cancel() {
        isCancelled.set(true)
    }

    suspend fun scanPorts(
        host: String,
        ports: List<Int>,
        onProgress: (Float) -> Unit,
        onPortFound: (PortScanResult) -> Unit
    ): List<PortScanResult> = withContext(Dispatchers.IO) {
        isCancelled.set(false)
        val openPorts = mutableListOf<PortScanResult>()
        val total = ports.size
        val completed = AtomicInteger(0)

        val batchSize = 15
        for (chunk in ports.chunked(batchSize)) {
            if (isCancelled.get()) break

            val results = coroutineScope {
                chunk.map { port ->
                    async {
                        val res = checkPort(host, port)
                        val done = completed.incrementAndGet()
                        onProgress(done.toFloat() / total.toFloat())
                        res
                    }
                }.awaitAll().filterNotNull()
            }

            for (res in results) {
                openPorts.add(res)
                onPortFound(res)
            }
        }

        openPorts.sortedBy { it.port }
    }

    private fun checkPort(host: String, port: Int): PortScanResult? {
        val service = commonPorts[port] ?: "Unknown Service"
        return try {
            Socket().use { socket ->
                socket.soTimeout = 400
                socket.connect(InetSocketAddress(host, port), 400)

                var banner = ""
                try {
                    val reader = BufferedReader(InputStreamReader(socket.getInputStream()))
                    if (reader.ready()) {
                        banner = reader.readLine()?.take(50) ?: ""
                    }
                } catch (_: Exception) {}

                PortScanResult(
                    port = port,
                    serviceName = service,
                    status = PortStatus.OPEN,
                    banner = banner
                )
            }
        } catch (_: Exception) {
            null
        }
    }
}
