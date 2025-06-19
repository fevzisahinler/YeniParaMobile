import SwiftUI

struct RefreshButton: View {
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(AppColors.cardBackground)
                .frame(width: 42, height: 42)
                .overlay(
                    Circle()
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )
                .overlay(
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                        .rotationEffect(.degrees(isLoading ? 360 : 0))
                        .animation(
                            isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                            value: isLoading
                        )
                )
        }
    }
}
