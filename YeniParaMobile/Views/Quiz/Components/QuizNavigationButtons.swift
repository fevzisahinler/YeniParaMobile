import SwiftUI

struct QuizNavigationButtons: View {
    let canGoBack: Bool
    let canProceed: Bool
    let isLastQuestion: Bool
    let isLoading: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Gradient overlay for smooth transition
            LinearGradient(
                colors: [
                    Color(red: 28/255, green: 29/255, blue: 36/255).opacity(0),
                    Color(red: 28/255, green: 29/255, blue: 36/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 40)
            
            HStack(spacing: 12) {
                // Back button
                if canGoBack {
                    Button(action: onPrevious) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Önceki")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                }
                
                // Next/Complete button
                Button(action: onNext) {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(0.8)
                        } else {
                            Text(isLastQuestion ? "Tamamla" : "Sonraki")
                                .font(.system(size: 16, weight: .semibold))
                            
                            if !isLastQuestion {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                    }
                    .foregroundColor(canProceed && !isLoading ? .black : .white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                canProceed && !isLoading ?
                                AppColors.primary :
                                Color.white.opacity(0.15)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                canProceed && !isLoading ?
                                Color.clear :
                                Color.white.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                    .animation(.easeInOut(duration: 0.2), value: canProceed)
                }
                .disabled(!canProceed || isLoading)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .background(
            Color(red: 28/255, green: 29/255, blue: 36/255)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}