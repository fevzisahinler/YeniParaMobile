import SwiftUI

struct QuizResultView: View {
    let result: QuizSubmitData?
    let onComplete: () -> Void
    
    @State private var showContent = false
    @State private var showDetails = false
    @State private var animateProgress = false
    @State private var animateAllocation = false
    
    var profileTypeInfo: ProfileTypeInfo {
        guard let profile = result?.investorProfile else {
            return ProfileTypeInfo(
                title: "Bilinmeyen",
                description: "Profil tipi belirlenemedi",
                color: AppColors.textSecondary,
                icon: "questionmark.circle",
                emoji: "❓"
            )
        }
        
        return ProfileTypeHelper.getProfileInfo(for: profile)
    }
    
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
            
            // Animated background
            QuizResultBackground(
                profileColor: profileTypeInfo.color,
                showContent: showContent
            )
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 32) {
                        // Success Animation
                        QuizResultHeader(
                            profileInfo: profileTypeInfo,
                            showContent: showContent
                        )
                        .padding(.top, 40)
                        
                        // Profile Type Card
                        QuizResultProfileCard(
                            profileInfo: profileTypeInfo,
                            totalPoints: result?.totalPoints,
                            showDetails: showDetails
                        )
                        .padding(.horizontal, 20)
                        
                        // Portfolio Allocation
                        if let profile = result?.investorProfile {
                            QuizResultAllocation(
                                profile: profile,
                                profileColor: profileTypeInfo.color,
                                animateAllocation: animateAllocation
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        // Recommendations
                        if let recommendations = result?.recommendations, !recommendations.isEmpty {
                            QuizRecommendations(
                                recommendations: recommendations,
                                profileColor: profileTypeInfo.color,
                                animateProgress: animateProgress
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        // Bottom spacing
                        Spacer(minLength: 100)
                    }
                }
                
                // Fixed Bottom Button
                QuizResultBottomButton(
                    profileColor: profileTypeInfo.color,
                    animateProgress: animateProgress,
                    onComplete: onComplete
                )
            }
        }
        .onAppear {
            animateResult()
        }
    }
    
    private func animateResult() {
        showContent = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showDetails = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            animateAllocation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            animateProgress = true
        }
    }
}