import SwiftUI

struct FavoritesListView: View {
    let favoriteStocks: [UISymbol]
    let onRemoveFavorite: (String) -> Void
    let onStockTap: (UISymbol) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(favoriteStocks, id: \.code) { stock in
                    Button(action: { onStockTap(stock) }) {
                        FavoriteListItem(
                            stock: stock,
                            onRemove: {
                                onRemoveFavorite(stock.code)
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }
}
