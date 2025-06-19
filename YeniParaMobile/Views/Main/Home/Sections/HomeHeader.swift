import SwiftUI

struct HomeHeaderView: View {
    let favoriteCount: Int
    let isLoading: Bool
    let onFavoritesAction: () -> Void
    let onRefreshAction: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Piyasalar")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    LivePriceIndicator(isAnimating: isLoading)
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    FavoritesButton(
                        count: favoriteCount,
                        action: onFavoritesAction
                    )
                    
                    RefreshButton(
                        isLoading: isLoading,
                        action: onRefreshAction
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(AppColors.background)
    }
}
