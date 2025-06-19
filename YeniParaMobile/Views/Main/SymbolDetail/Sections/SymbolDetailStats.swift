import SwiftUI

struct SymbolDetailStats: View {
    @ObservedObject var viewModel: SymbolDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("İstatistikler")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 20)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(title: "Piyasa Değeri", value: viewModel.fundamental?.marketCapitalization?.formattedAbbreviated ?? "N/A")
                StatCard(title: "F/K Oranı", value: String(format: "%.2f", viewModel.fundamental?.peRatio ?? 0))
                StatCard(title: "Temettü Verimi", value: String(format: "%.2f%%", viewModel.fundamental?.dividendYield ?? 0))
                StatCard(title: "HBK", value: String(format: "$%.2f", viewModel.fundamental?.earningsShare ?? 0))
            }
            .padding(.horizontal, 20)
        }
    }
}
