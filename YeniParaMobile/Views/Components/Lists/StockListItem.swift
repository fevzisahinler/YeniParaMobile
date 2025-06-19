import SwiftUI

struct StockListItem: View {
    let stock: UISymbol
    let isFavorite: Bool
    let matchScore: Int
    let onFavoriteToggle: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            StockCard(
                stock: stock,
                isFavorite: isFavorite,
                onFavoriteToggle: onFavoriteToggle
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

