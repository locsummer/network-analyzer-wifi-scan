import SwiftUI

struct PingView: View {
    @ObservedObject var viewModel: NetworkViewModel
    @State private var hostInput = "8.8.8.8"
    @State private var count = 10
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Input Bar
                VStack(spacing: 12) {
                    HStack {
                        TextField("Host or IP Address", text: $hostInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        Button {
                            if viewModel.isPinging {
                                viewModel.stopPing()
                            } else {
                                viewModel.startPing(host: hostInput, count: count)
                            }
                        } label: {
                            Image(systemName: viewModel.isPinging ? "stop.fill" : "play.fill")
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(viewModel.isPinging ? Color.red : Color.blue)
                                .cornerRadius(8)
                        }
                    }
                    
                    // Quick Preset Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(["8.8.8.8", "1.1.1.1", "google.com", "apple.com"], id: \.self) { preset in
                                Button(preset) {
                                    hostInput = preset
                                }
                                .font(.caption.monospaced())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(UIColor.tertiarySystemBackground))
                                .cornerRadius(6)
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color(UIColor.secondarySystemBackground))
                
                // Statistics Summary Card
                if let summary = viewModel.pingSummary {
                    VStack(spacing: 8) {
                        Text("Statistics for \(summary.ip)")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 16) {
                            StatCell(title: "Sent", value: "\(summary.packetsSent)")
                            StatCell(title: "Recv", value: "\(summary.packetsReceived)")
                            StatCell(title: "Loss", value: String(format: "%.0f%%", summary.packetLossPercent), isWarning: summary.packetLossPercent > 0)
                            StatCell(title: "Min", value: String(format: "%.1f ms", summary.minRttMs))
                            StatCell(title: "Avg", value: String(format: "%.1f ms", summary.avgRttMs))
                            StatCell(title: "Max", value: String(format: "%.1f ms", summary.maxRttMs))
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.tertiarySystemBackground))
                }
                
                // Packet List
                List {
                    ForEach(viewModel.pingPackets) { packet in
                        HStack {
                            Text("#\(packet.seq)")
                                .font(.caption.monospaced())
                                .foregroundColor(.secondary)
                            
                            Text(packet.isSuccess ? "\(packet.bytes) bytes from \(packet.ip)" : (packet.errorMessage ?? "Request Timeout"))
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundColor(packet.isSuccess ? .primary : .red)
                            
                            Spacer()
                            
                            if packet.isSuccess {
                                Text(String(format: "%.1f ms", packet.rttMs))
                                    .font(.system(.subheadline, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(packet.rttMs < 50 ? .green : (packet.rttMs < 150 ? .orange : .red))
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Ping")
        }
    }
}

struct StatCell: View {
    let title: String
    let value: String
    var isWarning: Bool = false
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(isWarning ? .red : .primary)
        }
    }
}
