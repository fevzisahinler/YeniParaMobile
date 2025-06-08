import SwiftUI

// MARK: - Favorite Stock Row Component
struct FavoriteStockRow: View {
    let stock: UISymbol
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Stock Logo/Icon
            AsyncImage(url: URL(string: "http://localhost:4000\(stock.logoPath)")) { image in
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
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 48, height: 48)
            .cornerRadius(12)
            
            // Stock Info
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.code)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(stock.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Price Info
            VStack(alignment: .trailing, spacing: 4) {
                Text(stock.formattedPrice)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: 4) {
                    Image(systemName: stock.isPositive ? "triangle.fill" : "triangle.fill")
                        .font(.system(size: 8))
                        .rotationEffect(.degrees(stock.isPositive ? 0 : 180))
                        .foregroundColor(stock.changeColor)
                    
                    Text(stock.formattedChangePercent)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(stock.changeColor)
                }
            }
            
            // Remove Button
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
        .contentShape(Rectangle())
    }
}