import SwiftUI

// MARK: - StockLogo Component
struct StockLogo: View {
    let path: String
    let code: String
    let size: CGFloat
    
    var body: some View {
        StockLogoView(
            logoPath: path,
            stockCode: code,
            size: size
        )
    }
}

// MARK: - PriceInfo Component
struct PriceInfo: View {
    let stock: UISymbol
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(stock.formattedPrice)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: 4) {
                Image(systemName: stock.isPositive ? "arrow.up" : "arrow.down")
                    .font(.system(size: 9, weight: .bold))
                
                Text(stock.formattedChangePercent)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(stock.changeColor)
        }
    }
}

// MARK: - FavoriteToggleButton Component
struct FavoriteToggleButton: View {
    let isFavorite: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 18))
                .foregroundColor(isFavorite ? AppColors.error : AppColors.textTertiary)
                .frame(width: 32, height: 32)
        }
    }
}

// MARK: - MatchScoreBadge Component
struct MatchScoreBadge: View {
    let score: Int
    
    var body: some View {
        if score > 70 {
            Text("%\(score)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppColors.primary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(AppColors.primary.opacity(0.15))
                )
        }
    }
}
