import SwiftUI

// MARK: - Favorites Sheet
struct FavoritesSheet: View {
    let favoriteStocks: Set<String>
    let allStocks: [UISymbol]
    let onRemoveFavorite: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private var favoriteStocksList: [UISymbol] {
        allStocks.filter { favoriteStocks.contains($0.code) }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if favoriteStocksList.isEmpty {
                        FavoritesEmptyView()
                    } else {
                        FavoritesListView(
                            favoriteStocksList: favoriteStocksList,
                            onRemoveFavorite: onRemoveFavorite
                        )
                    }
                }
            }
            .navigationTitle("Favorilerim")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackground(AppColors.background)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }
}

// MARK: - Favorites Empty View
struct FavoritesEmptyView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 64))
                .foregroundColor(AppColors.textTertiary)
            
            Text("Favorileriniz Boş")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Beğendiğiniz hisseleri kalp butonuna tıklayarak favorilerinize ekleyebilirsiniz.")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Favorites List View
struct FavoritesListView: View {
    let favoriteStocksList: [UISymbol]
    let onRemoveFavorite: (String) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(favoriteStocksList, id: \.code) { stock in
                    NavigationLink(destination: SymbolDetailView(symbol: stock.code)) {
                        FavoriteStockRow(
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

// MARK: - Navigation Bar Extension
extension View {
    func navigationBarBackground(_ color: Color) -> some View {
        self.background(
            color
                .ignoresSafeArea(.container, edges: .top)
        )
    }
}
