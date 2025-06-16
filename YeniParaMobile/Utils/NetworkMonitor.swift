// Create this file: YeniParaMobile/Utils/NetworkMonitor.swift

import Network
import SwiftUI
import Combine

// MARK: - Network Monitor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected: Bool = true
    @Published var connectionType: ConnectionType = .unknown
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.updateConnectionType(path)
            }
        }
        monitor.start(queue: queue)
    }
    
    private func updateConnectionType(_ path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else {
            connectionType = .unknown
        }
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - Network Alert View
struct NetworkAlertView: View {
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    @State private var showAlert = false
    
    var body: some View {
        EmptyView()
            .alert("İnternet Bağlantısı Yok", isPresented: $showAlert) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text("Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin.")
            }
            .onChange(of: networkMonitor.isConnected) { newValue in
                if !newValue {
                    showAlert = true
                }
            }
    }
}

// MARK: - Offline Banner View
struct OfflineBannerView: View {
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    @State private var isVisible = false
    
    var body: some View {
        VStack {
            if !networkMonitor.isConnected && isVisible {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 14))
                    
                    Text("İnternet bağlantısı yok")
                        .font(.system(size: 14, weight: .medium))
                    
                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.red)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isVisible)
        .onAppear {
            isVisible = !networkMonitor.isConnected
        }
        .onChange(of: networkMonitor.isConnected) { newValue in
            withAnimation {
                isVisible = !newValue
            }
        }
    }
}
