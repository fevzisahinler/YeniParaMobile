import SwiftUI

struct StockCard: View {
    let stock: UISymbol
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Stock Logo
            StockLogoView(
                logoPath: stock.logoPath,
                stockCode: stock.code,
                size: 44
            )
            
            // Stock Info
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.code)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(stock.name)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Price Info
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
            
            // Favorite Button
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
                .fill(isPressed ? AppColors.cardBackground.opacity(0.8) : AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                isPressed = pressing
            },
            perform: {}
        )
    }
}
