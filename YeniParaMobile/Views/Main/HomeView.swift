import SwiftUI
import Combine

struct HomeView: View {
    @ObservedObject var authVM: AuthViewModel
    @StateObject private var viewModel = HomeViewModel()
    @State private var searchText = ""
    @State private var selectedFilter: FilterType = .all
    @State private var favoriteStocks: Set<String> = []
    @State private var showingFavorites = false
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Section
                HomeHeaderSection(
                    favoriteStocks: favoriteStocks,
                    isLoading: viewModel.isLoading,
                    onFavoritesAction: {
                        showingFavorites = true
                    },
                    onRefreshAction: {
                        Task {
                            await viewModel.refreshData()
                        }
                    }
                )
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Search Section
                        HomeSearchSection(
                            searchText: $searchText,
                            selectedFilter: $selectedFilter,
                            filters: FilterType.allCases,
                            getFilterCount: getFilterCount
                        )
                        
                        // Top Movers Section
                        if !viewModel.topGainers.isEmpty || !viewModel.topLosers.isEmpty {
                            HomeTopMoversSection(
                                topGainers: viewModel.topGainers,
                                topLosers: viewModel.topLosers,
                                favoriteStocks: favoriteStocks,
                                onFilterAction: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedFilter = .gainers
                                    }
                                },
                                calculateMatchScore: calculateMatchScore,
                                toggleFavorite: toggleFavorite
                            )
                        }
                        
                        // Stocks List Section
                        HomeStocksListSection(
                            stocks: viewModel.filteredStocks,
                            favoriteStocks: favoriteStocks,
                            isLoading: viewModel.isLoading,
                            isEmpty: viewModel.filteredStocks.isEmpty,
                            searchText: searchText,
                            calculateMatchScore: calculateMatchScore,
                            toggleFavorite: toggleFavorite
                        )
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
                .refreshable {
                    await viewModel.refreshData()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.loadData()
            }
            loadFavorites()
        }
        .onChange(of: searchText) { newValue in
            viewModel.searchText = newValue
        }
        .onChange(of: selectedFilter) { newValue in
            viewModel.selectedFilter = newValue
        }
        .overlay(
            Group {
                if viewModel.showError {
                    HomeErrorOverlay(
                        errorMessage: viewModel.errorMessage,
                        onRetry: {
                            Task {
                                await viewModel.refreshData()
                            }
                        }
                    )
                }
            }
        )
        .sheet(isPresented: $showingFavorites) {
            FavoritesSheet(
                favoriteStocks: favoriteStocks,
                allStocks: viewModel.stocks,
                onRemoveFavorite: { stockCode in
                    toggleFavorite(stockCode)
                }
            )
        }
    }
    
    // MARK: - Helper Functions
    private func toggleFavorite(_ stockCode: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if favoriteStocks.contains(stockCode) {
                favoriteStocks.remove(stockCode)
            } else {
                favoriteStocks.insert(stockCode)
            }
            saveFavorites()
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteStocks), forKey: "favoriteStocks")
    }
    
    private func loadFavorites() {
        if let saved = UserDefaults.standard.stringArray(forKey: "favoriteStocks") {
            favoriteStocks = Set(saved)
        }
    }
    
    private func calculateMatchScore(for stock: UISymbol) -> Int {
        let baseScore = 50
        let volatilityFactor = min(abs(stock.changePercent) * 2, 20)
        let volumeFactor = stock.volume > 1_000_000 ? 10 : 5
        let trendFactor = stock.isPositive ? 15 : -5
        let priceStabilityFactor = stock.price > 10 ? 10 : 0
        
        let totalScore = baseScore + Int(volatilityFactor) + volumeFactor + trendFactor + priceStabilityFactor
        return min(max(totalScore, 0), 100)
    }
    
    private func getFilterCount(for filter: FilterType) -> Int {
        switch filter {
        case .all:
            return viewModel.stocks.count
        case .popular:
            return min(50, viewModel.stocks.count)
        case .gainers:
            return viewModel.stocks.filter { $0.changePercent > 0 }.count
        case .favorites:
            return favoriteStocks.count
        }
    }
}

// MARK: - Error Overlay
struct HomeErrorOverlay: View {
    let errorMessage: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundColor(AppColors.error)
            
            VStack(spacing: 8) {
                Text("Bağlantı Hatası")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(errorMessage)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: onRetry) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Tekrar Dene")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(AppColors.primary)
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.opacity(0.95))
        .edgesIgnoringSafeArea(.all)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HomeView(authVM: AuthViewModel())
        }
        .preferredColorScheme(.dark)
    }
}
