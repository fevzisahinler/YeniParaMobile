import SwiftUI

struct QuizView: View {
    @ObservedObject var authVM: AuthViewModel
    @StateObject private var quizVM = QuizViewModel()
    @State private var navigateToHome = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 28/255, green: 29/255, blue: 36/255),
                        Color(red: 20/255, green: 21/255, blue: 28/255)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if quizVM.isLoading && quizVM.questions.isEmpty {
                    LoadingView(message: "Sorular yükleniyor...")
                        .transition(.opacity)
                } else if quizVM.showError {
                    ErrorView(message: quizVM.errorMessage, onRetry: {
                        Task {
                            await quizVM.loadQuestions()
                        }
                    })
                    .transition(.opacity)
                } else if quizVM.showResult && quizVM.quizResult != nil {
                    QuizResultView(
                        result: quizVM.quizResult,
                        onComplete: {
                            Task {
                                await authVM.checkQuizStatus()
                                authVM.isQuizCompleted = true
                                navigateToHome = true
                            }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                } else if !quizVM.questions.isEmpty {
                    QuizContentView(quizVM: quizVM)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .animation(.easeInOut(duration: 0.5), value: quizVM.showResult)
            .animation(.easeInOut(duration: 0.3), value: quizVM.isLoading)
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToHome) {
                TabBarView(authVM: authVM)
                    .navigationBarBackButtonHidden(true)
            }
        }
        .onAppear {
            Task {
                await quizVM.loadQuestions()
            }
        }
    }
}

#Preview {
    QuizView(authVM: AuthViewModel())
        .preferredColorScheme(.dark)
}