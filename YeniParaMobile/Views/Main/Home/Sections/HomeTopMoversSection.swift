import SwiftUI

struct HomeTopMoversSection: View {
    let topGainers: [UISymbol]
    let topLosers: [UISymbol]
    let favoriteStocks: Set<String>
    let onFavoriteToggle: (String) -> Void
    
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Section Header with Tab
            HStack {
                Text("En Çok Hareket Edenler")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                // Tab Selector
                HStack(spacing: 0) {
                    TabButton(title: "Yükselenler", isSelected: selectedTab == 0) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = 0
                        }
                    }
                    
                    TabButton(title: "Düşenler", isSelected: selectedTab == 1) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = 1
                        }
                    }
                }
                .background(AppColors.cardBackground)
                .cornerRadius(8)
            }
            .padding(.horizontal, 20)
            
            // Content
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(selectedTab == 0 ? topGainers : topLosers, id: \.code) { stock in
                        NavigationLink(destination: SymbolDetailView(symbol: stock.code)) {
                            TopMoverCard(
                                stock: stock,
                                isGainer: selectedTab == 0,
                                isFavorite: favoriteStocks.contains(stock.code),
                                matchScore: calculateMatchScore(for: stock),
                                onFavoriteToggle: {
                                    onFavoriteToggle(stock.code)
                                }
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func calculateMatchScore(for stock: UISymbol) -> Int {
        // This would come from QuizService in real implementation
        return Int.random(in: 40...95)
    }
}

// MARK: - Tab Button Component
private struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .black : AppColors.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppColors.primary : Color.clear)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
}
