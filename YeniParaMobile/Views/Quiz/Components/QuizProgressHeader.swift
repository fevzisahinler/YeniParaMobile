import SwiftUI

struct QuizProgressHeader: View {
    let currentIndex: Int
    let totalQuestions: Int
    let progressPercentage: Double
    
    var body: some View {
        VStack(spacing: 20) {
            // Progress Bar
            VStack(spacing: 12) {
                HStack {
                    Text("Soru \(currentIndex + 1)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text("\(currentIndex + 1)/\(totalQuestions)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.secondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progressPercentage, height: 6)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progressPercentage)
                    }
                }
                .frame(height: 6)
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
        }
    }
}