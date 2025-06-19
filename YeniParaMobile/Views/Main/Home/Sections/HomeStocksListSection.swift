import SwiftUI

struct HomeStocksListSection: View {
    let stocks: [UISymbol]
    let favoriteStocks: Set<String>
    let isLoading: Bool
    let searchText: String
    let onFavoriteToggle: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            if searchText.isEmpty {
                HStack {
                    Text("Tüm Hisseler")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(stocks.count) hisse")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.horizontal, 20)
            }
            
            // Stock List
            StockListSection(
                stocks: stocks,
                favoriteStocks: favoriteStocks,
                isLoading: isLoading,
                searchText: searchText,
                onFavoriteToggle: onFavoriteToggle,
                onStockTap: { stock in
                    // Navigation will be handled by NavigationLink in StockListSection
                }
            )
        }
    }
}
