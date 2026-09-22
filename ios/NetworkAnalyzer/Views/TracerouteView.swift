import SwiftUI

struct TracerouteView: View {
    @ObservedObject var viewModel: NetworkViewModel
    @State private var hostInput = "1.1.1.1"
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Bar
                VStack(spacing: 12) {
                    HStack {
                        TextField("Destination Host or IP", text: $hostInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        Button {
                            if viewModel.isTracing {
                                viewModel.stopTraceroute()
                            } else {
                                viewModel.startTraceroute(host: hostInput)
                            }
                        } label: {
                            Image(systemName: viewModel.isTracing ? "stop.fill" : "play.fill")
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(viewModel.isTracing ? Color.red : Color.blue)
                                .cornerRadius(8)
                        }
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(["1.1.1.1", "8.8.8.8", "apple.com", "google.com"], id: \.self) { preset in
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
                
                // Hops List
                if viewModel.tracerouteHops.isEmpty && !viewModel.isTracing {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                            .font(.system(size: 56))
                            .foregroundColor(.secondary)
                        Text("Traceroute Diagnostics")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Enter a domain or IP and tap 'Play' to trace network route hops.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(viewModel.tracerouteHops) { hop in
                            HStack(spacing: 12) {
                                Text("\(hop.hopNumber)")
                                    .font(.caption.bold())
                                    .frame(width: 24, height: 24)
                                    .background(Color.blue.opacity(0.15))
                                    .foregroundColor(.blue)
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(hop.ipAddress)
                                        .font(.system(.subheadline, design: .monospaced))
                                        .fontWeight(.medium)
                                    
                                    if !hop.hostname.isEmpty {
                                        Text(hop.hostname)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if hop.isSuccessful && hop.rttMs > 0 {
                                    Text(String(format: "%.1f ms", hop.rttMs))
                                        .font(.system(.subheadline, design: .monospaced))
                                        .foregroundColor(.green)
                                } else {
                                    Text("* * *")
                                        .font(.system(.subheadline, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Traceroute")
        }
    }
}
