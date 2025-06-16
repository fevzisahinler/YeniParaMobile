import SwiftUI

// MARK: - Top Mover Card Component
struct TopMoverCard: View {
    let stock: UISymbol
    let isGainer: Bool
    let isFavorite: Bool
    let matchScore: Int
    let onFavoriteToggle: () -> Void
    
    @State private var isPressed = false
    
    var cardGradient: LinearGradient {
        if isGainer {
            return LinearGradient(
                colors: [AppColors.primary.opacity(0.15), AppColors.primary.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [AppColors.error.opacity(0.15), AppColors.error.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var borderColor: Color {
        isGainer ? AppColors.primary.opacity(0.3) : AppColors.error.opacity(0.3)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with favorite button and match score
            HStack {
                // Match Score Badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(isGainer ? AppColors.primary : AppColors.error)
                        .frame(width: 6, height: 6)
                    
                    Text("\(matchScore)%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isGainer ? AppColors.primary : AppColors.error)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill((isGainer ? AppColors.primary : AppColors.error).opacity(0.1))
                )
                
                Spacer()
                
                // Favorite Button
                Button(action: onFavoriteToggle) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 14))
                        .foregroundColor(isFavorite ? AppColors.error : AppColors.textSecondary)
                }
            }
            
            // Stock Logo
            AsyncImage(url: URL(string: "http://192.168.1.210:4000\(stock.logoPath)")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [AppColors.primary, AppColors.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text(String(stock.code.prefix(2)))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 40, height: 40)
            .cornerRadius(12)
            
            // Stock Info
            VStack(spacing: 8) {
                VStack(spacing: 2) {
                    Text(stock.code)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(stock.name)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                
                // Price and Change
                VStack(spacing: 4) {
                    Text(stock.formattedPrice)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: isGainer ? "triangle.fill" : "triangle.fill")
                            .font(.system(size: 8))
                            .rotationEffect(.degrees(isGainer ? 0 : 180))
                            .foregroundColor(stock.changeColor)
                        
                        Text(stock.formattedChangePercent)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(stock.changeColor)
                    }
                }
            }
            
            // Volume Info
            VStack(spacing: 2) {
                Text("Hacim")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(AppColors.textTertiary)
                
                Text(stock.formattedVolume)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(16)
        .frame(width: 140)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(borderColor, lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
    }
}