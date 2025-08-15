import SwiftUI

struct ContentView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var initialLoadComplete = false
    @State private var showLoadingScreen = true

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            if showLoadingScreen && authVM.isLoggedIn && !initialLoadComplete {
                // Login sonrası yükleme ekranı
                VStack(spacing: 24) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                        .scaleEffect(1.5)
                    
                    Text("Hazırlanıyor...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .transition(.opacity)
            } else {
                Group {
                    if authVM.isLoggedIn {
                        if authVM.isQuizCompleted {
                            // Quiz tamamlanmış, ana uygulamaya yönlendir
                            TabBarView(authVM: authVM)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        } else {
                            // Kullanıcı giriş yapmış ama quiz tamamlamamış
                            QuizView(authVM: authVM)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }
                    } else {
                        // Kullanıcı giriş yapmamış, onboarding göster
                        NavigationStack {
                            WelcomeView(authVM: authVM)
                                .navigationBarHidden(true)
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                    }
                }
                .opacity(initialLoadComplete ? 1 : 0)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            setupInitialState()
        }
        .onChange(of: authVM.isLoggedIn) { oldValue, newValue in
            if newValue {
                handleLoginTransition()
            } else {
                // Logout durumunda
                withAnimation(.easeInOut(duration: 0.3)) {
                    initialLoadComplete = true
                    showLoadingScreen = false
                }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: authVM.isLoggedIn)
        .animation(.easeInOut(duration: 0.5), value: authVM.isQuizCompleted)
        .animation(.easeInOut(duration: 0.3), value: showLoadingScreen)
    }
    
    private func setupInitialState() {
        if authVM.isLoggedIn {
            // Quiz durumunu kontrol et
            Task {
                await checkQuizStatusSafely()
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.initialLoadComplete = true
                        self.showLoadingScreen = false
                    }
                }
            }
        } else {
            // Giriş yapılmamışsa direkt göster
            withAnimation(.easeInOut(duration: 0.3)) {
                initialLoadComplete = true
                showLoadingScreen = false
            }
        }
    }
    
    private func checkQuizStatusSafely() async {
            do {
                // Quiz durumunu güvenli şekilde kontrol et
                let response = try await APIService.shared.getQuizStatus()
                
                if response.success {
                    await MainActor.run {
                        self.authVM.isQuizCompleted = response.data.quizCompleted
                        // Debug logging removed for production
                    }
                } else {
                    // Debug logging removed for production
                    // API başarısız olursa quiz'e yönlendir (güvenli taraf)
                    await MainActor.run {
                        self.authVM.isQuizCompleted = false
                    }
                }
            } catch {
                // Debug logging removed for production
                
                // Hata durumunda:
                // 1. Token problemi varsa logout yap
                if case APIError.unauthorized = error {
                    await MainActor.run {
                        self.authVM.logout()
                    }
                } else {
                    // 2. Diğer API hatalarında quiz'e yönlendir (güvenli taraf)
                    await MainActor.run {
                        self.authVM.isQuizCompleted = false
                    }
                }
            }
        }
    
    private func handleLoginTransition() {
        // Login olduğunda kısa bir yükleme göster
        showLoadingScreen = true
        initialLoadComplete = false
        
        Task {
            // Quiz durumunu kontrol et
            await checkQuizStatusSafely()
            
            // Minimum 300ms bekle (çok hızlı geçişi önlemek için)
            try? await Task.sleep(for: .milliseconds(300))
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showLoadingScreen = false
                    initialLoadComplete = true
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(authVM: AuthViewModel())
            .preferredColorScheme(.dark)
    }
}
