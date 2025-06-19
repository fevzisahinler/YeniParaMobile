import SwiftUI

// MARK: - Profile Type Info Model
struct ProfileTypeInfo {
    let title: String
    let description: String
    let color: Color
    let icon: String
    let emoji: String
}

// MARK: - Profile Type Helper
struct ProfileTypeHelper {
    static func getProfileInfo(for profile: InvestorProfile) -> ProfileTypeInfo {
        let profileType = profile.profileType.lowercased()
        let title = profile.name
        let description = profile.description
        
        let color: Color
        let icon: String
        let emoji: String
        
        switch profileType {
        case "conservative":
            color = Color(red: 52/255, green: 152/255, blue: 219/255) // Soft blue
            icon = "shield.fill"
            emoji = "🛡️"
        case "moderate":
            color = Color(red: 243/255, green: 156/255, blue: 18/255) // Orange
            icon = "scale.3d"
            emoji = "⚖️"
        case "growth":
            color = AppColors.secondary
            icon = "chart.line.uptrend.xyaxis"
            emoji = "📈"
        case "aggressive":
            color = AppColors.primary
            icon = "flame.fill"
            emoji = "🔥"
        default:
            color = AppColors.primary
            icon = "person.crop.circle"
            emoji = "👤"
        }
        
        return ProfileTypeInfo(
            title: title,
            description: description,
            color: color,
            icon: icon,
            emoji: emoji
        )
    }
}

// MARK: - Quiz Result Background
struct QuizResultBackground: View {
    let profileColor: Color
    let showContent: Bool
    
    var body: some View {
        GeometryReader { geometry in
            Circle()
                .fill(profileColor.opacity(0.05))
                .frame(width: 300, height: 300)
                .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.2)
                .blur(radius: 80)
                .scaleEffect(showContent ? 1.1 : 0.9)
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: showContent)
            
            Circle()
                .fill(profileColor.opacity(0.03))
                .frame(width: 400, height: 400)
                .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.7)
                .blur(radius: 100)
                .scaleEffect(showContent ? 1.0 : 1.2)
                .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: showContent)
        }
    }
}

// MARK: - Quiz Result Header
struct QuizResultHeader: View {
    let profileInfo: ProfileTypeInfo
    let showContent: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated Icon
            ZStack {
                // Outer ring animation
                Circle()
                    .stroke(profileInfo.color.opacity(0.3), lineWidth: 3)
                    .frame(width: 120, height: 120)
                    .scaleEffect(showContent ? 1.1 : 0.9)
                    .opacity(showContent ? 0 : 1)
                    .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: showContent)
                
                // Main circle
                Circle()
                    .fill(profileInfo.color.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(profileInfo.color, lineWidth: 2)
                    )
                    .scaleEffect(showContent ? 1.0 : 0.3)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showContent)
                
                // Icon
                Image(systemName: profileInfo.icon)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(profileInfo.color)
                    .scaleEffect(showContent ? 1.0 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.3), value: showContent)
            }
            
            // Title and Subtitle
            VStack(spacing: 12) {
                Text("Tebrikler! \(profileInfo.emoji)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.5), value: showContent)
                
                Text("Yatırımcı tipiniz belirlendi")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.6), value: showContent)
            }
        }
    }
}

// MARK: - Quiz Result Profile Card
struct QuizResultProfileCard: View {
    let profileInfo: ProfileTypeInfo
    let totalPoints: Int?
    let showDetails: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Profile Name
            Text(profileInfo.title)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(profileInfo.color)
                .opacity(showDetails ? 1 : 0)
                .scaleEffect(showDetails ? 1 : 0.8)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.8), value: showDetails)
            
            // Description
            Text(profileInfo.description)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 24)
                .opacity(showDetails ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(1.0), value: showDetails)
            
            // Score Badge
            if let score = totalPoints {
                HStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 16))
                        .foregroundColor(profileInfo.color)
                    
                    Text("Puanınız: \(score)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 16))
                        .foregroundColor(profileInfo.color)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(profileInfo.color.opacity(0.15))
                        .overlay(
                            Capsule()
                                .stroke(profileInfo.color.opacity(0.3), lineWidth: 1)
                        )
                )
                .opacity(showDetails ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.2), value: showDetails)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(profileInfo.color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Quiz Result Bottom Button
struct QuizResultBottomButton: View {
    let profileColor: Color
    let animateProgress: Bool
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Gradient fade
            LinearGradient(
                colors: [
                    Color(red: 28/255, green: 29/255, blue: 36/255).opacity(0),
                    Color(red: 28/255, green: 29/255, blue: 36/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)
            
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                onComplete()
            }) {
                HStack(spacing: 12) {
                    Text("Uygulamaya Başla")
                        .font(.system(size: 18, weight: .bold))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(profileColor)
                        .shadow(color: profileColor.opacity(0.3), radius: 16, x: 0, y: 8)
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
            .background(Color(red: 28/255, green: 29/255, blue: 36/255))
            .opacity(animateProgress ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(2.0), value: animateProgress)
        }
    }
}
