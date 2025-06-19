import SwiftUI

struct MarketOverviewSection: View {
    @ObservedObject var authVM: AuthViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Piyasa Durumu")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                NavigationLink(destination: HomeView(authVM: authVM)) {
                    Text("Tümünü Gör")
                        .font(.subheadline)
                        .foregroundColor(AppColors.primary)
                }
            }
            .padding(.horizontal, AppConstants.screenPadding)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    MarketCard(title: "S&P 500", value: "4,567.23", change: "+2.34%", isPositive: true)
                    MarketCard(title: "NASDAQ", value: "14,432.12", change: "-0.89%", isPositive: false)
                    MarketCard(title: "Dow Jones", value: "34,876.45", change: "+1.12%", isPositive: true)
                    MarketCard(title: "VIX", value: "18.45", change: "-3.21%", isPositive: false)
                }
                .padding(.horizontal, AppConstants.screenPadding)
            }
        }
    }
}

struct MarketCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            Text(change)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isPositive ? AppColors.primary : AppColors.error)
        }
        .padding(AppConstants.cardPadding)
        .frame(width: 120)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )
        )
    }
}
