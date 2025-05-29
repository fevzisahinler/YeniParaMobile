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

struct MarketStatCard_Previews: PreviewProvider {
    static var previews: some View {
        MarketStatCard(
            title: "S&P 500",
            value: "4,567.23",
            change: "+2.34%",
            isPositive: true
        )
        .padding()
        .background(Color(red: 28/255, green: 29/255, blue: 36/255))
        .preferredColorScheme(.dark)
        .previewLayout(.sizeThatFits)
    }
}
