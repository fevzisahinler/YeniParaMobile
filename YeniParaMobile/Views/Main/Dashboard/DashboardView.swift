import SwiftUI

struct DashboardView: View {
    @ObservedObject var authVM: AuthViewModel
        @StateObject private var viewModel = ServiceLocator.makeDashboardViewModel()
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    DashboardHeaderView()
                    MarketOverviewSection(authVM: authVM)
                    FeaturedStocksSection(viewModel: viewModel)
                    QuickActionsSection()
                    MarketNewsSection(viewModel: viewModel)
                }
                .padding(.vertical, 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadDashboardData()
        }
    }
}
