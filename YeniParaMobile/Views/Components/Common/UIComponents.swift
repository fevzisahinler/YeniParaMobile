import SwiftUI

// MARK: - InfoRow Component
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - StatCard Component
struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            Text(value)
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppColors.cardBackground)
        .cornerRadius(8)
    }
}

// MARK: - ModernFilterChip Component
struct ModernFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(title)
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
