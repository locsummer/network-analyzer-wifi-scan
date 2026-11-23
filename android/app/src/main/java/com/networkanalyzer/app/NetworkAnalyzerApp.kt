package com.networkanalyzer.app

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.Devices
import androidx.compose.material.icons.filled.Dns
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Route
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.Wifi
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.networkanalyzer.app.ui.screens.DnsWhoisScreen
import com.networkanalyzer.app.ui.screens.InfoScreen
import com.networkanalyzer.app.ui.screens.LanScannerScreen
import com.networkanalyzer.app.ui.screens.PingScreen
import com.networkanalyzer.app.ui.screens.PortScannerScreen
import com.networkanalyzer.app.ui.screens.TracerouteScreen
import com.networkanalyzer.app.ui.screens.WifiScannerScreen
import com.networkanalyzer.app.viewmodels.NetworkViewModel

data class NavTab(
    val title: String,
    val icon: ImageVector
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NetworkAnalyzerApp(viewModel: NetworkViewModel) {
    val tabs = remember {
        listOf(
            NavTab("Info", Icons.Default.Info),
            NavTab("LAN", Icons.Default.Devices),
            NavTab("Wi-Fi", Icons.Default.Wifi),
            NavTab("Ping", Icons.Default.Bolt),
            NavTab("Trace", Icons.Default.Route),
            NavTab("Ports", Icons.Default.Security),
            NavTab("DNS", Icons.Default.Dns)
        )
    }
    var selectedIndex by remember { mutableIntStateOf(0) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Network Analyzer - ${tabs[selectedIndex].title}",
                        fontWeight = FontWeight.Bold,
                        fontSize = 18.sp
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    titleContentColor = MaterialTheme.colorScheme.onPrimary
                )
            )
        },
        bottomBar = {
            NavigationBar(
                containerColor = MaterialTheme.colorScheme.surface
            ) {
                tabs.forEachIndexed { index, tab ->
                    NavigationBarItem(
                        selected = selectedIndex == index,
                        onClick = { selectedIndex = index },
                        icon = { Icon(imageVector = tab.icon, contentDescription = tab.title) },
                        label = { Text(text = tab.title, fontSize = 10.sp) }
                    )
                }
            }
        }
    ) { innerPadding ->
        Box(modifier = Modifier.padding(innerPadding)) {
            when (selectedIndex) {
                0 -> InfoScreen(viewModel)
                1 -> LanScannerScreen(viewModel)
                2 -> WifiScannerScreen(viewModel)
                3 -> PingScreen(viewModel)
                4 -> TracerouteScreen(viewModel)
                5 -> PortScannerScreen(viewModel)
                6 -> DnsWhoisScreen(viewModel)
            }
        }
    }
}
