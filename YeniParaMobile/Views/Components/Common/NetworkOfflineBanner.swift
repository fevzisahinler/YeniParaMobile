import SwiftUI

struct NetworkOfflineBanner: View {
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
                .background(AppColors.error)
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
