import SwiftUI

struct ContentView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var showQuiz = false

    var body: some View {
        Group {
            if authVM.isLoggedIn {
                // Kullanıcı giriş yapmış ama quiz tamamlamamış
                if !authVM.isQuizCompleted {
                    QuizView(authVM: authVM)
                } else {
                    // Quiz tamamlanmış, ana uygulamaya yönlendir
                    TabBarView(authVM: authVM)
                }
            } else {
                // Kullanıcı giriş yapmamış, onboarding göster
                NavigationStack {
                    WelcomeView(authVM: authVM)
                        .navigationBarHidden(true)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Uygulama açıldığında quiz durumunu kontrol et
            if authVM.isLoggedIn && authVM.accessToken != nil {
                Task {
                    await authVM.checkQuizStatus()
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
