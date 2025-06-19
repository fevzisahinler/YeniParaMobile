import SwiftUI

// MARK: - Quiz Result Allocation
struct QuizResultAllocation: View {
    let profile: InvestorProfile
    let profileColor: Color
    let animateAllocation: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 20))
                    .foregroundColor(profileColor)
                
                Text("Önerilen Portföy Dağılımı")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                AllocationRow(
                    title: "Hisse Senedi",
                    percentage: profile.stockAllocationPercentage,
                    color: AppColors.primary,
                    icon: "chart.line.uptrend.xyaxis",
                    animate: animateAllocation
                )
                
                AllocationRow(
                    title: "Tahvil",
                    percentage: profile.bondAllocationPercentage,
                    color: Color(red: 52/255, green: 152/255, blue: 219/255),
                    icon: "doc.text",
                    animate: animateAllocation
                )
                
                AllocationRow(
                    title: "Nakit",
                    percentage: profile.cashAllocationPercentage,
                    color: Color(red: 155/255, green: 89/255, blue: 182/255),
                    icon: "banknote",
                    animate: animateAllocation
                )
            }
            .padding(.vertical, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .opacity(animateAllocation ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(1.5), value: animateAllocation)
    }
}

// MARK: - Allocation Row
struct AllocationRow: View {
    let title: String
    let percentage: Int
    let color: Color
    let icon: String
    let animate: Bool
    
    @State private var progressWidth: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("%\(percentage)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: progressWidth, height: 8)
                }
                .onAppear {
                    if animate {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                            progressWidth = geometry.size.width * CGFloat(percentage) / 100
                        }
                    }
                }
                .onChange(of: animate) { newValue in
                    if newValue {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                            progressWidth = geometry.size.width * CGFloat(percentage) / 100
                        }
                    }
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Quiz Recommendations
struct QuizRecommendations: View {
    let recommendations: [String]
    let profileColor: Color
    let animateProgress: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 20))
                    .foregroundColor(profileColor)
                
                Text("Size Özel Öneriler")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(Array(recommendations.enumerated()), id: \.element) { index, recommendation in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(profileColor)
                            .frame(width: 8, height: 8)
                            .padding(.top, 6)
                        
                        Text(recommendation)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                            .lineSpacing(3)
                        
                        Spacer()
                    }
                    .opacity(animateProgress ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(1.8 + Double(index) * 0.1), value: animateProgress)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}