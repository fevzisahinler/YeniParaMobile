import SwiftUI

struct FilterChip: View {
    let filter: FilterType
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: filter.icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(filter.displayName)
                    .font(.system(size: 14, weight: .medium))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? .black.opacity(0.2) : Color.white.opacity(0.2))
                        )
                }
            }
            .foregroundColor(isSelected ? .black : AppColors.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? AppColors.primary : AppColors.cardBackground)
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? Color.clear : AppColors.cardBorder, lineWidth: 1)
                    )
            )
        }
    }
}
