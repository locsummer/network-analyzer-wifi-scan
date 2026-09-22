import SwiftUI

struct InfoView: View {
    @ObservedObject var viewModel: NetworkViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Status Header Card
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(viewModel.networkSummary.isConnected ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: viewModel.networkSummary.connectionType == .wifi ? "wifi" : "antenna.radiowaves.left.and.right")
                                .font(.system(size: 24))
                                .foregroundColor(viewModel.networkSummary.isConnected ? .green : .red)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.networkSummary.connectionType.rawValue)
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Text(viewModel.networkSummary.wifiSsid != "-" ? viewModel.networkSummary.wifiSsid : viewModel.networkSummary.localIpv4)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            viewModel.refreshNetworkInfo()
                        } label: {
                            if viewModel.isRefreshingInfo {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(16)
                    
                    // Wi-Fi Details (if connected to Wi-Fi)
                    if viewModel.networkSummary.connectionType == .wifi {
                        MetricCard(title: "Wi-Fi Information", iconName: "wifi", accentColor: .blue) {
                            MetricRow(label: "SSID", value: viewModel.networkSummary.wifiSsid)
                            MetricRow(label: "BSSID", value: viewModel.networkSummary.wifiBssid)
                        }
                    }
                    
                    // IP Configuration
                    MetricCard(title: "IP Configuration", iconName: "network", accentColor: .cyan) {
                        MetricRow(label: "Interface", value: viewModel.networkSummary.interfaceName)
                        MetricRow(label: "Local IPv4", value: viewModel.networkSummary.localIpv4, isMonospaced: true)
                        MetricRow(label: "Subnet Mask", value: viewModel.networkSummary.subnetMask, isMonospaced: true)
                        MetricRow(label: "Default Gateway", value: viewModel.networkSummary.defaultGateway, isMonospaced: true)
                        MetricRow(label: "Broadcast IP", value: viewModel.networkSummary.broadcastIp, isMonospaced: true)
                        if viewModel.networkSummary.localIpv6 != "-" {
                            MetricRow(label: "Local IPv6", value: viewModel.networkSummary.localIpv6, isMonospaced: true)
                        }
                    }
                    
                    // External WAN & DNS
                    MetricCard(title: "External WAN & DNS", iconName: "globe", accentColor: .purple) {
                        MetricRow(label: "Public IP", value: viewModel.networkSummary.publicIp, isMonospaced: true)
                        MetricRow(label: "ISP", value: viewModel.networkSummary.ispName)
                        MetricRow(label: "Location", value: viewModel.networkSummary.location)
                        MetricRow(label: "DNS Servers", value: viewModel.networkSummary.dnsServers.joined(separator: ", "), isMonospaced: true)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Network Info")
        }
    }
}
