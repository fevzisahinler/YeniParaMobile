import SwiftUI

// MARK: - Home Header Section
struct HomeHeaderSection: View {
    let favoriteStocks: Set<String>
    let isLoading: Bool
    let onFavoritesAction: () -> Void
    let onRefreshAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hisse Senetleri")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        
                        Text("Canlı Fiyatlar")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Favorites Button
                    Button(action: onFavoritesAction) {
                        ZStack {
                            Circle()
                                .fill(AppColors.cardBackground)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(AppColors.cardBorder, lineWidth: 1)
                                )
                            
                            Image(systemName: "heart.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(AppColors.primary)
                            
                            if !favoriteStocks.isEmpty {
                                Text("\(favoriteStocks.count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(minWidth: 16, minHeight: 16)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 14, y: -14)
                            }
                        }
                    }
                    
                    // Refresh Button
                    Button(action: onRefreshAction) {
                        Circle()
                            .fill(AppColors.cardBackground)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(AppColors.cardBorder, lineWidth: 1)
                            )
                            .overlay(
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                                    .rotationEffect(.degrees(isLoading ? 360 : 0))
                                    .animation(
                                        isLoading ?
                                        .linear(duration: 1).repeatForever(autoreverses: false) :
                                        .default,
                                        value: isLoading
                                    )
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(AppColors.background)
    }
}

// MARK: - Search Section
struct HomeSearchSection: View {
    @Binding var searchText: String
    @Binding var selectedFilter: FilterType
    let filters: [FilterType]
    let getFilterCount: (FilterType) -> Int
    
    var body: some View {
        VStack(spacing: 20) {
            // Search Bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                
                TextField("Hisse ara...", text: $searchText)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textPrimary)
                    .autocapitalization(.allCharacters)
                
                if !searchText.isEmpty {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            searchText = ""
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(AppColors.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.cardBorder, lineWidth: 1)
            )
            
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(filters, id: \.self) { filter in
                        ModernFilterChip(
                            title: filter.displayName,
                            icon: filter.icon,
                            isSelected: selectedFilter == filter,
                            count: getFilterCount(filter)
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFilter = filter
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Top Movers Section
struct HomeTopMoversSection: View {
    let topGainers: [UISymbol]
    let topLosers: [UISymbol]
    let favoriteStocks: Set<String>
    let onFilterAction: () -> Void
    let calculateMatchScore: (UISymbol) -> Int
    let toggleFavorite: (String) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Günün Yıldızları")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Button(action: onFilterAction) {
                    HStack(spacing: 6) {
                        Text("Tümünü Gör")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(topGainers.prefix(3), id: \.code) { stock in
                        NavigationLink(destination: SymbolDetailView(symbol: stock.code)) {
                            TopMoverCard(
                                stock: stock,
                                isGainer: true,
                                isFavorite: favoriteStocks.contains(stock.code),
                                matchScore: calculateMatchScore(stock)
                            ) {
                                toggleFavorite(stock.code)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    ForEach(topLosers.prefix(2), id: \.code) { stock in
                        NavigationLink(destination: SymbolDetailView(symbol: stock.code)) {
                            TopMoverCard(
                                stock: stock,
                                isGainer: false,
                                isFavorite: favoriteStocks.contains(stock.code),
                                matchScore: calculateMatchScore(stock)
                            ) {
                                toggleFavorite(stock.code)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Stocks List Section
struct HomeStocksListSection: View {
    let stocks: [UISymbol]
    let favoriteStocks: Set<String>
    let isLoading: Bool
    let isEmpty: Bool
    let searchText: String
    let calculateMatchScore: (UISymbol) -> Int
    let toggleFavorite: (String) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Hisseler")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text("\(stocks.count) hisse")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppColors.cardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.cardBorder, lineWidth: 1)
                    )
            }
            .padding(.horizontal, 20)
            
            if isLoading && stocks.isEmpty {
                LoadingView(message: "Hisse verileri yükleniyor...")
                    .frame(height: 200)
            } else if isEmpty {
                HomeEmptyView(searchText: searchText)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(stocks, id: \.code) { stock in
                        NavigationLink(destination: SymbolDetailView(symbol: stock.code)) {
                            EnhancedStockRow(
                                stock: stock,
                                isFavorite: favoriteStocks.contains(stock.code),
                                matchScore: calculateMatchScore(stock)
                            ) {
                                toggleFavorite(stock.code)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Empty View
struct HomeEmptyView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "chart.line.uptrend.xyaxis" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textTertiary)
            
            Text(searchText.isEmpty ? "Henüz hisse yok" : "Sonuç bulunamadı")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            
            Text(searchText.isEmpty ? "Veriler yükleniyor..." : "Başka bir arama yapmayı deneyin")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
 
