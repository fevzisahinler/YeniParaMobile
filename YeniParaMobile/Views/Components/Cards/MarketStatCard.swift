import SwiftUI

struct MarketStatCard: View {
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
            
            if !change.isEmpty {
                Text(change)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isPositive ? AppColors.primary : AppColors.error)
            }
        }
        .padding(AppConstants.cardPadding)
        .frame(width: 140)
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
