import SwiftUI

struct DnsWhoisView: View {
    @ObservedObject var viewModel: NetworkViewModel
    @State private var queryInput = "google.com"
    @State private var selectedTab = 0 // 0: DNS, 1: WHOIS
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Input
                VStack(spacing: 12) {
                    HStack {
                        TextField("Domain or IP Address", text: $queryInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        Button {
                            viewModel.queryDnsAndWhois(query: queryInput)
                        } label: {
                            if viewModel.isQueryingDnsWhois {
                                ProgressView()
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                            } else {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    Picker("Tab", selection: $selectedTab) {
                        Text("DNS Records (\(viewModel.dnsRecords.count))").tag(0)
                        Text("WHOIS Lookup").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(16)
                .background(Color(UIColor.secondarySystemBackground))
                
                // Content
                if selectedTab == 0 {
                    // DNS Records
                    if viewModel.dnsRecords.isEmpty && !viewModel.isQueryingDnsWhois {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "server.rack")
                                .font(.system(size: 56))
                                .foregroundColor(.secondary)
                            Text("No DNS records found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(viewModel.dnsRecords) { record in
                                HStack {
                                    Text(record.type)
                                        .font(.system(size: 11, weight: .bold))
                                        .frame(width: 50)
                                        .padding(.vertical, 4)
                                        .background(record.type == "A" ? Color.green : (record.type == "AAAA" ? Color.cyan : Color.orange))
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(record.value)
                                            .font(.system(.subheadline, design: .monospaced))
                                            .fontWeight(.bold)
                                        Text("Host: \(record.name) • TTL: \(record.ttl)s")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                } else {
                    // WHOIS View
                    if let whois = viewModel.whoisResult {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 14) {
                                MetricCard(title: "Registrar Details", iconName: "building.2", accentColor: .blue) {
                                    MetricRow(label: "Query", value: whois.query)
                                    if !whois.registrar.isEmpty { MetricRow(label: "Registrar", value: whois.registrar) }
                                    if !whois.creationDate.isEmpty { MetricRow(label: "Created On", value: whois.creationDate) }
                                    if !whois.expirationDate.isEmpty { MetricRow(label: "Expires On", value: whois.expirationDate) }
                                }
                                
                                if !whois.nameServers.isEmpty {
                                    MetricCard(title: "Name Servers", iconName: "network", accentColor: .purple) {
                                        ForEach(whois.nameServers, id: \.self) { ns in
                                            Text("• \(ns)")
                                                .font(.system(.caption, design: .monospaced))
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                
                                MetricCard(title: "Raw Output", iconName: "doc.plaintext", accentColor: .gray) {
                                    Text(whois.rawText.prefix(2000))
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(16)
                        }
                    } else {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "person.text.rectangle")
                                .font(.system(size: 56))
                                .foregroundColor(.secondary)
                            Text("No WHOIS information")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("DNS & WHOIS")
        }
    }
}
