import SwiftUI

struct HomeView: View {
    @ObservedObject var authVM: AuthViewModel
        @StateObject private var viewModel = ServiceLocator.makeHomeViewModel()
        @State private var showingFavorites = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HomeHeaderSection(
                        favoriteStocks: viewModel.favoriteStocks,
                        isLoading: viewModel.isLoading,
                        onFavoritesAction: { showingFavorites = true },
                        onRefreshAction: { Task { await viewModel.refreshData() } }
                    )
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            HomeSearchBar(text: $viewModel.searchText)
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                            
                            HomeFilterSection(
                                selectedFilter: $viewModel.selectedFilter,
                                getFilterCount: viewModel.getFilterCount
                            )
                            
                            if viewModel.shouldShowTopMovers {
                                HomeTopMoversSection(
                                    topGainers: viewModel.topGainers,
                                    topLosers: viewModel.topLosers,
                                    favoriteStocks: viewModel.favoriteStocks,
                                    onFavoriteToggle: viewModel.toggleFavorite
                                )
                            }
                            
                            HomeStocksListSection(
                                stocks: viewModel.filteredStocks,
                                favoriteStocks: viewModel.favoriteStocks,
                                isLoading: viewModel.isLoading,
                                searchText: viewModel.searchText,
                                onFavoriteToggle: viewModel.toggleFavorite
                            )
                        }
                        .padding(.bottom, 100)
                    }
                }
                
                if viewModel.showError {
                    ErrorBanner(
                        message: viewModel.errorMessage,
                        onRetry: { Task { await viewModel.refreshData() } }
                    )
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingFavorites) {
            FavoritesSheet(
                favoriteStocks: viewModel.favoriteStocks,
                allStocks: viewModel.stocks,
                onRemoveFavorite: viewModel.toggleFavorite
            )
        }
        .task {
            await viewModel.loadData()
        }
    }
}
