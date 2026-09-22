import SwiftUI

struct LanScannerView: View {
    @ObservedObject var viewModel: NetworkViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header & Action Bar
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.isScanningLan ? "Scanning Subnet..." : "\(viewModel.lanDevices.count) Devices Found")
                                .font(.headline)
                            Text("Subnet: \(viewModel.networkSummary.localIpv4)/24")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            if viewModel.isScanningLan {
                                viewModel.stopLanScan()
                            } else {
                                viewModel.startLanScan()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: viewModel.isScanningLan ? "stop.fill" : "play.fill")
                                Text(viewModel.isScanningLan ? "Stop" : "Scan")
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(viewModel.isScanningLan ? Color.red : Color.blue)
                            .cornerRadius(10)
                        }
                    }
                    
                    if viewModel.isScanningLan {
                        ProgressView(value: viewModel.lanScanProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    }
                }
                .padding(16)
                .background(Color(UIColor.secondarySystemBackground))
                
                // Device List
                if viewModel.lanDevices.isEmpty && !viewModel.isScanningLan {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "laptopcomputer.and.iphone")
                            .font(.system(size: 56))
                            .foregroundColor(.secondary)
                        Text("No devices scanned yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Tap 'Scan' to discover all active devices on your local network.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(viewModel.lanDevices) { device in
                            HStack(spacing: 12) {
                                Image(systemName: device.isGateway ? "router" : (device.isLocalDevice ? "iphone" : "desktopcomputer"))
                                    .font(.system(size: 22))
                                    .foregroundColor(device.isGateway ? .purple : .blue)
                                    .frame(width: 36, height: 36)
                                    .background(device.isGateway ? Color.purple.opacity(0.15) : Color.blue.opacity(0.15))
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(device.ipAddress)
                                            .font(.system(.subheadline, design: .monospaced))
                                            .fontWeight(.bold)
                                        
                                        if device.isGateway {
                                            Text("Router")
                                                .font(.system(size: 10, weight: .bold))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.purple)
                                                .foregroundColor(.white)
                                                .cornerRadius(4)
                                        } else if device.isLocalDevice {
                                            Text("You")
                                                .font(.system(size: 10, weight: .bold))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.green)
                                                .foregroundColor(.white)
                                                .cornerRadius(4)
                                        }
                                    }
                                    
                                    Text(device.hostname.isEmpty ? device.vendor : device.hostname)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if device.responseTimeMs > 0 {
                                    Text("\(Int(device.responseTimeMs)) ms")
                                        .font(.caption.monospaced())
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("LAN Scanner")
        }
    }
}
