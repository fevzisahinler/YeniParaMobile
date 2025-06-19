import SwiftUI

struct SymbolDetailCompanyInfo: View {
    @ObservedObject var viewModel: SymbolDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Şirket Bilgileri")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 0) {
                if let fundamental = viewModel.fundamental {
                    InfoRow(title: "Sektör", value: fundamental.sector ?? "N/A")
                    InfoRow(title: "Endüstri", value: fundamental.industry ?? "N/A")
                    InfoRow(title: "Ülke", value: fundamental.country ?? "N/A")
                    InfoRow(title: "Borsa", value: fundamental.exchange)
                    InfoRow(title: "Web Sitesi", value: fundamental.webUrl ?? "N/A")
                }
            }
            .padding(16)
            .background(AppColors.cardBackground)
            .cornerRadius(12)
            .padding(.horizontal, 20)
        }
    }
}
