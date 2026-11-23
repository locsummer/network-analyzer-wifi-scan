package com.networkanalyzer.app.viewmodels

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.networkanalyzer.app.data.DiscoveredDevice
import com.networkanalyzer.app.data.DnsRecordItem
import com.networkanalyzer.app.data.NetworkSummary
import com.networkanalyzer.app.data.PingPacket
import com.networkanalyzer.app.data.PingSummary
import com.networkanalyzer.app.data.PortScanResult
import com.networkanalyzer.app.data.TracerouteHop
import com.networkanalyzer.app.data.WhoisResult
import com.networkanalyzer.app.data.WifiScanItem
import com.networkanalyzer.app.diagnostics.DnsWhoisService
import com.networkanalyzer.app.diagnostics.LanScannerService
import com.networkanalyzer.app.diagnostics.NetworkInfoService
import com.networkanalyzer.app.diagnostics.PingService
import com.networkanalyzer.app.diagnostics.PortScannerService
import com.networkanalyzer.app.diagnostics.TracerouteService
import com.networkanalyzer.app.diagnostics.WifiScannerService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class NetworkViewModel(application: Application) : AndroidViewModel(application) {

    private val infoService = NetworkInfoService(application)
    private val lanScannerService = LanScannerService()
    private val wifiScannerService = WifiScannerService(application)
    private val pingService = PingService()
    private val tracerouteService = TracerouteService()
    private val portScannerService = PortScannerService()
    private val dnsWhoisService = DnsWhoisService()

    // 1. Info
    private val _networkSummary = MutableStateFlow(NetworkSummary())
    val networkSummary = _networkSummary.asStateFlow()

    private val _isRefreshingInfo = MutableStateFlow(false)
    val isRefreshingInfo = _isRefreshingInfo.asStateFlow()

    // 2. LAN Scan
    private val _lanDevices = MutableStateFlow<List<DiscoveredDevice>>(emptyList())
    val lanDevices = _lanDevices.asStateFlow()

    private val _isScanningLan = MutableStateFlow(false)
    val isScanningLan = _isScanningLan.asStateFlow()

    private val _lanScanProgress = MutableStateFlow(0f)
    val lanScanProgress = _lanScanProgress.asStateFlow()

    // 3. Wi-Fi Scan
    private val _wifiNetworks = MutableStateFlow<List<WifiScanItem>>(emptyList())
    val wifiNetworks = _wifiNetworks.asStateFlow()

    private val _isScanningWifi = MutableStateFlow(false)
    val isScanningWifi = _isScanningWifi.asStateFlow()

    // 4. Ping
    private val _pingPackets = MutableStateFlow<List<PingPacket>>(emptyList())
    val pingPackets = _pingPackets.asStateFlow()

    private val _pingSummary = MutableStateFlow<PingSummary?>(null)
    val pingSummary = _pingSummary.asStateFlow()

    private val _isPinging = MutableStateFlow(false)
    val isPinging = _isPinging.asStateFlow()

    // 5. Traceroute
    private val _tracerouteHops = MutableStateFlow<List<TracerouteHop>>(emptyList())
    val tracerouteHops = _tracerouteHops.asStateFlow()

    private val _isTracing = MutableStateFlow(false)
    val isTracing = _isTracing.asStateFlow()

    // 6. Port Scanner
    private val _openPorts = MutableStateFlow<List<PortScanResult>>(emptyList())
    val openPorts = _openPorts.asStateFlow()

    private val _isScanningPorts = MutableStateFlow(false)
    val isScanningPorts = _isScanningPorts.asStateFlow()

    private val _portScanProgress = MutableStateFlow(0f)
    val portScanProgress = _portScanProgress.asStateFlow()

    // 7. DNS & Whois
    private val _dnsRecords = MutableStateFlow<List<DnsRecordItem>>(emptyList())
    val dnsRecords = _dnsRecords.asStateFlow()

    private val _whoisResult = MutableStateFlow<WhoisResult?>(null)
    val whoisResult = _whoisResult.asStateFlow()

    private val _isQueryingDnsWhois = MutableStateFlow(false)
    val isQueryingDnsWhois = _isQueryingDnsWhois.asStateFlow()

    init {
        refreshNetworkInfo()
    }

    // Refresh Network Info
    fun refreshNetworkInfo() {
        if (_isRefreshingInfo.value) return
        _isRefreshingInfo.value = true
        viewModelScope.launch {
            val summary = infoService.fetchNetworkSummary()
            _networkSummary.value = summary
            _isRefreshingInfo.value = false
        }
    }

    // LAN Scanner
    fun startLanScan() {
        if (_isScanningLan.value) return
        _isScanningLan.value = true
        _lanDevices.value = emptyList()
        _lanScanProgress.value = 0f

        viewModelScope.launch {
            val localIp = _networkSummary.value.localIpv4
            val gatewayIp = _networkSummary.value.defaultGateway
            val devices = lanScannerService.scanSubnet(
                localIp = localIp,
                gatewayIp = gatewayIp,
                onProgress = { progress -> _lanScanProgress.value = progress },
                onDeviceFound = { dev ->
                    if (_lanDevices.value.none { it.ipAddress == dev.ipAddress }) {
                        _lanDevices.value = _lanDevices.value + dev
                    }
                }
            )
            _lanDevices.value = devices
            _isScanningLan.value = false
            _lanScanProgress.value = 1f
        }
    }

    fun stopLanScan() {
        lanScannerService.cancel()
        _isScanningLan.value = false
    }

    // Wi-Fi Scanner
    fun scanWifiNetworks() {
        if (_isScanningWifi.value) return
        _isScanningWifi.value = true
        viewModelScope.launch {
            val list = wifiScannerService.scanWifiNetworks()
            _wifiNetworks.value = list
            _isScanningWifi.value = false
        }
    }

    // Ping
    fun startPing(host: String, count: Int = 10) {
        if (_isPinging.value || host.isBlank()) return
        _isPinging.value = true
        _pingPackets.value = emptyList()
        _pingSummary.value = null

        viewModelScope.launch {
            val summary = pingService.runPing(host, count) { packet ->
                _pingPackets.value = _pingPackets.value + packet
            }
            _pingSummary.value = summary
            _isPinging.value = false
        }
    }

    fun stopPing() {
        pingService.cancel()
        _isPinging.value = false
    }

    // Traceroute
    fun startTrace(host: String, maxHops: Int = 30) {
        if (_isTracing.value || host.isBlank()) return
        _isTracing.value = true
        _tracerouteHops.value = emptyList()

        viewModelScope.launch {
            val hops = tracerouteService.traceRoute(host, maxHops) { hop ->
                _tracerouteHops.value = _tracerouteHops.value + hop
            }
            _tracerouteHops.value = hops
            _isTracing.value = false
        }
    }

    fun stopTrace() {
        tracerouteService.cancel()
        _isTracing.value = false
    }

    // Port Scanner
    fun startPortScan(host: String, ports: List<Int> = PortScannerService.commonPorts.keys.toList()) {
        if (_isScanningPorts.value || host.isBlank()) return
        _isScanningPorts.value = true
        _openPorts.value = emptyList()
        _portScanProgress.value = 0f

        viewModelScope.launch {
            val results = portScannerService.scanPorts(
                host = host,
                ports = ports,
                onProgress = { progress -> _portScanProgress.value = progress },
                onPortFound = { result ->
                    if (_openPorts.value.none { it.port == result.port }) {
                        _openPorts.value = _openPorts.value + result
                    }
                }
            )
            _openPorts.value = results
            _isScanningPorts.value = false
            _portScanProgress.value = 1f
        }
    }

    fun stopPortScan() {
        portScannerService.cancel()
        _isScanningPorts.value = false
    }

    // DNS & Whois
    fun queryDnsAndWhois(query: String) {
        if (_isQueryingDnsWhois.value || query.isBlank()) return
        _isQueryingDnsWhois.value = true
        _dnsRecords.value = emptyList()
        _whoisResult.value = null

        viewModelScope.launch {
            val dns = dnsWhoisService.queryDns(query)
            _dnsRecords.value = dns

            val whois = dnsWhoisService.queryWhois(query)
            _whoisResult.value = whois

            _isQueryingDnsWhois.value = false
        }
    }
}
