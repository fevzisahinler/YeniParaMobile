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


struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary)
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )
        )
    }
}
