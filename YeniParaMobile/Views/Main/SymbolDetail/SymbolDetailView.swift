import SwiftUI

struct SymbolDetailView: View {
    let symbol: String
        @StateObject private var viewModel = ServiceLocator.makeSymbolDetailViewModel()
        @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Bar
                SymbolDetailNavigationBar(
                    symbol: symbol,
                    isInWatchlist: viewModel.isInWatchlist,
                    onBack: { dismiss() },
                    onToggleWatchlist: { viewModel.toggleWatchlist() },
                    onShare: { viewModel.share() }
                )
                
                if viewModel.isLoading {
                    LoadingView()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            SymbolDetailHeader(viewModel: viewModel)
                            SymbolDetailChart(viewModel: viewModel)
                            SymbolDetailStats(viewModel: viewModel)
                            SymbolDetailCompanyInfo(viewModel: viewModel)
                            SymbolDetailActions(symbol: symbol)
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadData(for: symbol)
        }
    }
}
