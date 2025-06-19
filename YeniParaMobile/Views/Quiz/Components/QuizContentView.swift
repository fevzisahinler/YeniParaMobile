import SwiftUI

struct QuizContentView: View {
    @ObservedObject var quizVM: QuizViewModel
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: [
                    Color(red: 28/255, green: 29/255, blue: 36/255),
                    Color(red: 20/255, green: 21/255, blue: 28/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Header
                QuizProgressHeader(
                    currentIndex: quizVM.currentQuestionIndex,
                    totalQuestions: quizVM.questions.count,
                    progressPercentage: quizVM.progressPercentage
                )
                
                if let question = quizVM.currentQuestion {
                    ScrollView {
                        VStack(spacing: 32) {
                            // Question Text
                            Text(question.questionText)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 24)
                                .padding(.top, 40)
                            
                            // Options
                            VStack(spacing: 12) {
                                ForEach(question.options.sorted { $0.optionOrder < $1.optionOrder }) { option in
                                    QuizOptionCard(
                                        option: option,
                                        isSelected: quizVM.selectedOptionForCurrentQuestion == option.id,
                                        onTap: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                                impactFeedback.impactOccurred()
                                                quizVM.selectOption(option.id)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            // Bottom spacing for navigation
                            Spacer(minLength: 140)
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(question.id)
                }
                
                // Navigation Buttons
                QuizNavigationButtons(
                    canGoBack: quizVM.currentQuestionIndex > 0,
                    canProceed: quizVM.canProceed,
                    isLastQuestion: quizVM.isLastQuestion,
                    isLoading: quizVM.isLoading,
                    onPrevious: { quizVM.previousQuestion() },
                    onNext: { quizVM.nextQuestion() }
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: quizVM.currentQuestionIndex)
    }
}