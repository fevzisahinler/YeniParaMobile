import SwiftUI

struct SymbolDetailHeader: View {
    @ObservedObject var viewModel: SymbolDetailViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Company Info
            HStack(spacing: 16) {
                StockLogoView(
                    logoPath: viewModel.fundamental?.logoPath ?? "",
                    stockCode: viewModel.symbol,
                    size: 60
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.symbol)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(viewModel.fundamental?.name ?? "")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            
            // Price Info
            VStack(alignment: .leading, spacing: 8) {
                Text("$0.00") // Price from real-time data
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 14))
                        Text("+$0.00")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(AppColors.primary)
                    
                    Text("+0.00%")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.primary.opacity(0.15))
                        .cornerRadius(6)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}
