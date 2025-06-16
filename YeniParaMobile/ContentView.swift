import SwiftUI

struct ContentView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var initialLoadComplete = false

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            Group {
                if authVM.isLoggedIn && !initialLoadComplete {
                    // Show loading only on initial load
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                            .scaleEffect(1.5)
                        
                        Text("Yükleniyor...")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if authVM.isLoggedIn {
                    if !authVM.isQuizCompleted {
                        // Kullanıcı giriş yapmış ama quiz tamamlamamış
                        QuizView(authVM: authVM)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else {
                        // Quiz tamamlanmış, ana uygulamaya yönlendir
                        TabBarView(authVM: authVM)
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
            .animation(.easeInOut(duration: 0.5), value: authVM.isLoggedIn)
            .animation(.easeInOut(duration: 0.5), value: authVM.isQuizCompleted)
            .animation(.easeInOut(duration: 0.3), value: initialLoadComplete)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Check if we need to check quiz status
            if authVM.isLoggedIn && authVM.accessToken != nil && !initialLoadComplete {
                checkQuizStatus()
            } else {
                // If not logged in or no token, complete immediately
                initialLoadComplete = true
            }
        }
        .onChange(of: authVM.isLoggedIn) { newValue in
            if newValue && authVM.accessToken != nil {
                // When login status changes to true, check quiz status
                checkQuizStatus()
            } else if !newValue {
                // Reset when logging out
                initialLoadComplete = false
            }
        }
    }
    
    private func checkQuizStatus() {
        Task {
            // Check quiz status
            await authVM.checkQuizStatus()
            
            // Complete the initial load immediately after quiz check
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
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
