import SwiftUI

// MARK: - Enhanced Stock Row Component
struct EnhancedStockRow: View {
    let stock: UISymbol
    let isFavorite: Bool
    let matchScore: Int
    let onFavoriteToggle: () -> Void
    
    @State private var isPressed = false
    
    private var matchScoreColor: Color {
        switch matchScore {
        case 80...:
            return AppColors.primary
        case 60..<80:
            return Color.orange
        case 40..<60:
            return Color.yellow
        default:
            return AppColors.textTertiary
        }
    }
    
    private var matchScoreIcon: String {
        switch matchScore {
        case 80...:
            return "star.fill"
        case 60..<80:
            return "star.leadinghalf.filled"
        default:
            return "star"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
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
            .frame(width: 48, height: 48)
            .cornerRadius(12)
            
            // Stock Info
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(stock.code)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    // Match Score Badge
                    HStack(spacing: 3) {
                        Image(systemName: matchScoreIcon)
                            .font(.system(size: 8))
                            .foregroundColor(matchScoreColor)
                        
                        Text("\(matchScore)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(matchScoreColor)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(matchScoreColor.opacity(0.15))
                    )
                }
                
                Text(stock.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
                
                // Additional Info Row
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text("Vol:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppColors.textTertiary)
                        Text(stock.formattedVolume)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    HStack(spacing: 4) {
                        Text("Range:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppColors.textTertiary)
                        Text(stock.dayRange)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            // Price and Change Info
            VStack(alignment: .trailing, spacing: 6) {
                Text(stock.formattedPrice)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: 6) {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: stock.isPositive ? "triangle.fill" : "triangle.fill")
                                .font(.system(size: 8))
                                .rotationEffect(.degrees(stock.isPositive ? 0 : 180))
                                .foregroundColor(stock.changeColor)
                            
                            Text(stock.formattedChangePercent)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(stock.changeColor)
                        }
                        
                        Text(stock.formattedChange)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    // Favorite Button
                    Button(action: onFavoriteToggle) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundColor(isFavorite ? AppColors.error : AppColors.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(isFavorite ? AppColors.error.opacity(0.1) : AppColors.cardBackground)
                            )
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
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
        .contentShape(Rectangle())
    }
}