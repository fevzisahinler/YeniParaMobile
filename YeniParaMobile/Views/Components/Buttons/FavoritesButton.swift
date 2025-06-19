import SwiftUI

struct FavoritesButton: View {
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(AppColors.cardBackground)
                    .frame(width: 42, height: 42)
                    .overlay(
                        Circle()
                            .stroke(AppColors.cardBorder, lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: "heart.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.error)
                    )
                
                if count > 0 {
                    BadgeView(count: count)
                        .offset(x: 4, y: -4)
                }
            }
        }
    }
}
