package com.networkanalyzer.app.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.networkanalyzer.app.data.PingPacket
import com.networkanalyzer.app.data.PingSummary
import com.networkanalyzer.app.viewmodels.NetworkViewModel

@Composable
fun PingScreen(viewModel: NetworkViewModel) {
    var hostInput by remember { mutableStateOf("google.com") }
    val packets by viewModel.pingPackets.collectAsState()
    val summary by viewModel.pingSummary.collectAsState()
    val isPinging by viewModel.isPinging.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        // Input & Controls
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            OutlinedTextField(
                value = hostInput,
                onValueChange = { hostInput = it },
                label = { Text("Host or IP") },
                singleLine = true,
                modifier = Modifier.weight(1f),
                enabled = !isPinging
            )

            Button(
                onClick = {
                    if (isPinging) viewModel.stopPing() else viewModel.startPing(hostInput.trim())
                },
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (isPinging) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary
                ),
                shape = RoundedCornerShape(8.dp),
                modifier = Modifier.height(56.dp)
            ) {
                Icon(
                    imageVector = if (isPinging) Icons.Default.Stop else Icons.Default.PlayArrow,
                    contentDescription = null
                )
                Spacer(modifier = Modifier.size(4.dp))
                Text(text = if (isPinging) "Stop" else "Ping")
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Ping Summary Card (if finished or summary available)
        summary?.let { sum ->
            PingSummaryCard(sum)
            Spacer(modifier = Modifier.height(16.dp))
        }

        // Real-time Packets Stream
        Text(
            text = "Packet Responses (${packets.size})",
            fontSize = 16.sp,
            fontWeight = FontWeight.SemiBold
        )

        Spacer(modifier = Modifier.height(8.dp))

        LazyColumn(
            verticalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            items(packets, key = { it.seq }) { packet ->
                PingPacketRow(packet)
            }
        }
    }
}

@Composable
fun PingSummaryCard(summary: PingSummary) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer
        )
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            Text(
                text = "Ping Statistics for ${summary.host} (${summary.ip})",
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )
            Spacer(modifier = Modifier.height(8.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Text("Sent: ${summary.packetsSent}", fontSize = 12.sp)
                    Text("Received: ${summary.packetsReceived}", fontSize = 12.sp)
                    Text(
                        text = "Loss: ${String.format("%.1f%%", summary.packetLossPercent)}",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = if (summary.packetLossPercent > 0) MaterialTheme.colorScheme.error else Color(0xFF2E7D32)
                    )
                }
                Column(horizontalAlignment = Alignment.End) {
                    Text("Min: ${String.format("%.1f ms", summary.minRttMs)}", fontSize = 12.sp)
                    Text("Avg: ${String.format("%.1f ms", summary.avgRttMs)}", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    Text("Max: ${String.format("%.1f ms", summary.maxRttMs)}", fontSize = 12.sp)
                    Text("StdDev: ${String.format("%.1f ms", summary.stdDevRttMs)}", fontSize = 12.sp)
                }
            }
        }
    }
}

@Composable
fun PingPacketRow(packet: PingPacket) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(8.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Icon(
                    imageVector = if (packet.isSuccess) Icons.Default.CheckCircle else Icons.Default.Error,
                    contentDescription = null,
                    tint = if (packet.isSuccess) Color(0xFF2E7D32) else MaterialTheme.colorScheme.error,
                    modifier = Modifier.size(18.dp)
                )

                Text(
                    text = "#${packet.seq}",
                    fontWeight = FontWeight.Bold,
                    fontSize = 13.sp,
                    fontFamily = FontFamily.Monospace
                )

                Text(
                    text = if (packet.isSuccess) "${packet.bytes} bytes from ${packet.ip}" else (packet.errorMessage ?: "Timeout"),
                    fontSize = 13.sp,
                    color = if (packet.isSuccess) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.error
                )
            }

            if (packet.isSuccess) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        text = "ttl=${packet.ttl}",
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = String.format("%.1f ms", packet.rttMs),
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }
        }
    }
}
