import SwiftUI

struct ContentView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var initialLoadComplete = false

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            Group {
                if authVM.isLoggedIn {
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
        }
        .preferredColorScheme(.dark)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(authVM: AuthViewModel())
            .preferredColorScheme(.dark)
    }
}
