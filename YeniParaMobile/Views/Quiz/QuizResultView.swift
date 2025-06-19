import SwiftUI

// QuizResultView.swift dosyasına bu kodu ekleyin veya yeni bir dosya oluşturun

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
        withAnimation(.easeOut(duration: 0.5)) {
            showContent = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                showDetails = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                animateAllocation = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                animateProgress = true
            }
        }
    }
}

// MARK: - Quiz Result Allocation Component
struct QuizResultAllocation: View {
    let profile: InvestorProfile
    let profileColor: Color
    let animateAllocation: Bool
    
    @State private var animatedValues: [Double] = [0, 0, 0]
    
    private var allocations: [(String, Int, String)] {
        [
            ("Hisse Senedi", profile.stockAllocationPercentage, "chart.line.uptrend.xyaxis"),
            ("Tahvil", profile.bondAllocationPercentage, "doc.text"),
            ("Nakit", profile.cashAllocationPercentage, "banknote")
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Önerilen Portföy Dağılımı")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                ForEach(allocations.indices, id: \.self) { index in
                    let allocation = allocations[index]
                    
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: allocation.2)
                                .font(.system(size: 16))
                                .foregroundColor(profileColor)
                                .frame(width: 24)
                            
                            Text(allocation.0)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("%\(Int(animatedValues[index]))")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(profileColor)
                                .animation(nil, value: animatedValues[index])
                        }
                        
                        // Progress Bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.white.opacity(0.1))
                                
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(profileColor.opacity(0.8))
                                    .frame(width: geometry.size.width * (animatedValues[index] / 100))
                                    .animation(.spring(response: 0.8, dampingFraction: 0.8), value: animatedValues[index])
                            }
                        }
                        .frame(height: 12)
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(profileColor.opacity(0.2), lineWidth: 1)
                )
        )
        .onAppear {
            if animateAllocation {
                withAnimation(.easeOut(duration: 1.0)) {
                    animatedValues[0] = Double(allocations[0].1)
                }
                withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                    animatedValues[1] = Double(allocations[1].1)
                }
                withAnimation(.easeOut(duration: 1.0).delay(0.4)) {
                    animatedValues[2] = Double(allocations[2].1)
                }
            }
        }
        .onChange(of: animateAllocation) { newValue in
            if newValue {
                withAnimation(.easeOut(duration: 1.0)) {
                    animatedValues[0] = Double(allocations[0].1)
                }
                withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                    animatedValues[1] = Double(allocations[1].1)
                }
                withAnimation(.easeOut(duration: 1.0).delay(0.4)) {
                    animatedValues[2] = Double(allocations[2].1)
                }
            }
        }
    }
}

// MARK: - Quiz Recommendations Component
struct QuizRecommendations: View {
    let recommendations: [String]
    let profileColor: Color
    let animateProgress: Bool
    
    @State private var visibleRecommendations: [Bool] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Öneriler")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(recommendations.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 16) {
                        // Checkmark icon
                        ZStack {
                            Circle()
                                .fill(profileColor.opacity(0.15))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(profileColor)
                        }
                        .scaleEffect(visibleRecommendations.indices.contains(index) && visibleRecommendations[index] ? 1 : 0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double(index) * 0.15), value: visibleRecommendations)
                        
                        // Recommendation text
                        Text(recommendations[index])
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer(minLength: 0)
                    }
                    .opacity(visibleRecommendations.indices.contains(index) && visibleRecommendations[index] ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.15), value: visibleRecommendations)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(profileColor.opacity(0.2), lineWidth: 1)
                )
        )
        .onAppear {
            visibleRecommendations = Array(repeating: false, count: recommendations.count)
            
            if animateProgress {
                for index in recommendations.indices {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.15) {
                        if index < visibleRecommendations.count {
                            visibleRecommendations[index] = true
                        }
                    }
                }
            }
        }
        .onChange(of: animateProgress) { newValue in
            if newValue {
                for index in recommendations.indices {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.15) {
                        if index < visibleRecommendations.count {
                            visibleRecommendations[index] = true
                        }
                    }
                }
            }
        }
    }
}
