import SwiftUI

struct FavoriteStockRow: View {
    let stock: UISymbol
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Logo
            StockLogoView(
                logoPath: stock.logoPath,
                stockCode: stock.code,
                size: 48
            )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.code)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(stock.name)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Price info
            VStack(alignment: .trailing, spacing: 4) {
                Text(stock.formattedPrice)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: 4) {
                    Image(systemName: stock.isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10))
                    
                    Text(stock.formattedChangePercent)
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(stock.changeColor)
            }
            
            // Remove button
            Button(action: onRemove) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.error)
                    .frame(width: 32, height: 32)
                    .background(AppColors.error.opacity(0.1))
                    .clipShape(Circle())
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
    }
}
