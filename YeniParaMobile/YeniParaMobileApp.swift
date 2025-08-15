import SwiftUI

// MARK: - Enhanced Launch Screen
struct LaunchScreenView: View {
    @State private var isAnimating = false
    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var loadingOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 28/255, green: 29/255, blue: 36/255),
                    Color(red: 20/255, green: 21/255, blue: 28/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Logo with animation
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                
                // App name
                Text("YeniPara")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(textOpacity)
                
                // Tagline
                Text("Yatırımın Yeni Adresi")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(textOpacity)
                
                Spacer()
                
                // Loading indicator
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                        .scaleEffect(1.0)
                    
                    Text("Hazırlanıyor...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .opacity(loadingOpacity)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            animateLaunchScreen()
        }
    }
    
    private func animateLaunchScreen() {
        // Logo animation
        withAnimation(.easeOut(duration: 0.8)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Text animation
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            textOpacity = 1.0
        }
        
        // Loading animation
        withAnimation(.easeIn(duration: 0.5).delay(0.8)) {
            loadingOpacity = 1.0
        }
    }
}

// MARK: - Main App
@main
struct YeniParaMobileApp: App {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var marketRefreshManager = MarketDataRefreshManager.shared
    @StateObject private var marketDataCache = MarketDataCache.shared
    @State private var showLaunchScreen = true
    
    init() {
        // Customize navigation bar back button text
        UINavigationBar.appearance().backItem?.title = "Geri"
        UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(UIOffset(horizontal: 0, vertical: 0), for: .default)
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Dark background to prevent white flash
                Color(red: 28/255, green: 29/255, blue: 36/255)
                    .ignoresSafeArea()
                
                if showLaunchScreen {
                    LaunchScreenView()
                        .transition(.opacity)
                } else {
                    ContentView(authVM: authVM)
                        .transition(.opacity)
                        .environmentObject(networkMonitor)
                        .environmentObject(marketRefreshManager)
                        .environmentObject(marketDataCache)
                }
            }
            .preferredColorScheme(.dark)
            .animation(.easeInOut(duration: 0.5), value: showLaunchScreen)
            .onAppear {
                initializeApp()
            }
        }
    }
    
    private func initializeApp() {
        // Initialize services
        APIService.shared.setAuthViewModel(authVM)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showLaunchScreen = false
            }
        }
    }
}
