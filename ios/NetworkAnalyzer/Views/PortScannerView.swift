import SwiftUI

struct PortScannerView: View {
    @ObservedObject var viewModel: NetworkViewModel
    @State private var hostInput = "192.168.1.1"
    @State private var selectedProfile = "Common"
    
    let profiles = ["Common", "Web", "Remote", "Database"]
    
    var currentPorts: [Int] {
        switch selectedProfile {
        case "Web":
            return [80, 443, 8000, 8080, 8443, 8888]
        case "Remote":
            return [21, 22, 23, 3389, 5900]
        case "Database":
            return [1433, 1521, 3306, 5432, 6379, 27017]
        default:
            return Array(PortScannerService.commonPorts.keys).sorted()
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Control Bar
                VStack(spacing: 12) {
                    HStack {
                        TextField("Target IP or Host", text: $hostInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        Button {
                            if viewModel.isScanningPorts {
                                viewModel.stopPortScan()
                            } else {
                                viewModel.startPortScan(host: hostInput, ports: currentPorts)
                            }
                        } label: {
                            Image(systemName: viewModel.isScanningPorts ? "stop.fill" : "play.fill")
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(viewModel.isScanningPorts ? Color.red : Color.blue)
                                .cornerRadius(8)
                        }
                    }
                    
                    Picker("Profile", selection: $selectedProfile) {
                        ForEach(profiles, id: \.self) { profile in
                            Text(profile).tag(profile)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if viewModel.isScanningPorts {
                        ProgressView(value: viewModel.portScanProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    }
                }
                .padding(16)
                .background(Color(UIColor.secondarySystemBackground))
                
                // Open Ports List
                if viewModel.openPorts.isEmpty && !viewModel.isScanningPorts {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "lock.shield")
                            .font(.system(size: 56))
                            .foregroundColor(.secondary)
                        Text("No open ports found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Select a profile and start scan to detect open listening ports.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(viewModel.openPorts) { port in
                            HStack {
                                Text("OPEN")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Port \(port.port) / TCP")
                                        .font(.system(.subheadline, design: .monospaced))
                                        .fontWeight(.bold)
                                    
                                    Text(port.serviceName)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Port Scanner")
        }
    }
}
