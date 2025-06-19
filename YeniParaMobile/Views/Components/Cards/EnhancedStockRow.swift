import SwiftUI

struct EnhancedStockRow: View {
    let stock: UISymbol
    let isFavorite: Bool
    let matchScore: Int
    let onFavoriteToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Logo
            StockLogoView(
                logoPath: stock.logoPath,
                stockCode: stock.code,
                size: 44
            )
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(stock.code)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    // Match Score Badge
                    if matchScore > 70 {
                        Text("%\(matchScore)")
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
                
                Text(stock.name)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Price info
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
            
            // Favorite button
            Button(action: onFavoriteToggle) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 18))
                    .foregroundColor(isFavorite ? AppColors.error : AppColors.textTertiary)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )
        )
    }
}
