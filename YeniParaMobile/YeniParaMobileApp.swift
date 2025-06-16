import SwiftUI

// MARK: - Enhanced Launch Screen
struct LaunchScreenView: View {
    @State private var isAnimating = false
    @State private var progress: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color(red: 28/255, green: 29/255, blue: 36/255)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Logo with animation
                VStack(spacing: 20) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                        .opacity(isAnimating ? 1.0 : 0.7)
                    
                    Text("YeniPara")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(isAnimating ? 1.0 : 0)
                }
                
                // Loading indicator
                VStack(spacing: 16) {
                    // Custom loading bar
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 120, height: 4)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 143/255, green: 217/255, blue: 83/255),
                                        Color(red: 111/255, green: 170/255, blue: 12/255)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 120 * progress, height: 4)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                    
                    Text("Yükleniyor...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .opacity(isAnimating ? 1.0 : 0)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimating = true
            }
            
            // Simulate loading progress
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                withAnimation {
                    progress += 0.1
                    if progress >= 1.0 {
                        timer.invalidate()
                    }
                }
            }
        }
    }
}

// MARK: - Main App
@main
struct YeniParaMobileApp: App {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var showLaunchScreen = true
    @State private var isInitialized = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showLaunchScreen {
                    LaunchScreenView()
                        .transition(.opacity)
                } else {
                    ContentView(authVM: authVM)
                        .transition(.opacity)
                        .environmentObject(networkMonitor)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: showLaunchScreen)
            .onAppear {
                initializeApp()
            }
        }
    }
    
    private func initializeApp() {
        // Initialize services
        APIService.shared.setAuthViewModel(authVM)
        
        // Minimum display time for launch screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showLaunchScreen = false
                isInitialized = true
            }
        }
    }
}
