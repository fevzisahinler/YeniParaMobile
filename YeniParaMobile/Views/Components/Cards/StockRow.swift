import SwiftUI

struct StockRow: View {
    let stock: UISymbol
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 12) {
            StockLogo(path: stock.logoPath, code: stock.code, size: 44)
            
            StockInfo(stock: stock)
            
            Spacer()
            
            PriceInfo(stock: stock)
            
            FavoriteToggleButton(
                isFavorite: isFavorite,
                action: onFavoriteToggle
            )
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

struct StockInfo: View {
    let stock: UISymbol
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(stock.code)
                .font(.system(size: 15,  weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            
            Text(stock.name)
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
        }
    }
}
