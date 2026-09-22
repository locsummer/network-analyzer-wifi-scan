import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel = NetworkViewModel()
    
    var body: some View {
        TabView {
            InfoView(viewModel: viewModel)
                .tabItem {
                    Label("Info", systemImage: "info.circle.fill")
                }
            
            LanScannerView(viewModel: viewModel)
                .tabItem {
                    Label("LAN Scan", systemImage: "laptopcomputer.and.iphone")
                }
            
            PingView(viewModel: viewModel)
                .tabItem {
                    Label("Ping", systemImage: "bolt.horizontal.fill")
                }
            
            TracerouteView(viewModel: viewModel)
                .tabItem {
                    Label("Trace", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                }
            
            PortScannerView(viewModel: viewModel)
                .tabItem {
                    Label("Ports", systemImage: "lock.shield.fill")
                }
            
            DnsWhoisView(viewModel: viewModel)
                .tabItem {
                    Label("DNS/Whois", systemImage: "server.rack")
                }
        }
    }
}
