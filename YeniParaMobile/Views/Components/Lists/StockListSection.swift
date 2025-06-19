import SwiftUI

struct StockListSection: View {
    let stocks: [UISymbol]
    let favoriteStocks: Set<String>
    let isLoading: Bool
    let searchText: String
    let onFavoriteToggle: (String) -> Void
    let onStockTap: (UISymbol) -> Void
    
    var body: some View {
        LazyVStack(spacing: 8) {
            if isLoading {
                ForEach(0..<10, id: \.self) { _ in
                    LoadingStockRow()
                        .padding(.horizontal, 20)
                }
            } else if stocks.isEmpty {
                EmptyStateView(
                    title: searchText.isEmpty ? "Henüz hisse yok" : "Sonuç bulunamadı",
                    message: searchText.isEmpty ? "Veriler yükleniyor..." : "Başka bir arama yapmayı deneyin",
                    icon: searchText.isEmpty ? "chart.line.uptrend.xyaxis" : "magnifyingglass"
                )
                .frame(minHeight: 300)
            } else {
                ForEach(stocks, id: \.code) { stock in
                    StockListItem(
                        stock: stock,
                        isFavorite: favoriteStocks.contains(stock.code),
                        matchScore: calculateMatchScore(for: stock),
                        onFavoriteToggle: {
                            onFavoriteToggle(stock.code)
                        },
                        onTap: {
                            onStockTap(stock)
                        }
                    )
                    .padding(.horizontal, 20)
                }
            }
        }
        .padding(.top, 20)
    }
    
    private func calculateMatchScore(for stock: UISymbol) -> Int {
        // Bu hesaplama gerçek uygulamada QuizService'den gelecek
        return Int.random(in: 40...95)
    }
}
