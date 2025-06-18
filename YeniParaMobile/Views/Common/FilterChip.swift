import SwiftUI

// MARK: - Filter Types
enum FilterType: CaseIterable {
    case all
    case popular
    case gainers
    case losers
    case favorites
    
    var displayName: String {
        switch self {
        case .all: return "Tümü"
        case .popular: return "Popüler"
        case .gainers: return "Yükselenler"
        case .losers: return "Düşenler"
        case .favorites: return "Favoriler"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .popular: return "flame"
        case .gainers: return "arrow.up.right"
        case .losers: return "arrow.down.right"
        case .favorites: return "heart"
        }
    }
}

// MARK: - Modern Filter Chip Component
struct ModernFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(icon)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isSelected ? .black.opacity(0.7) : AppColors.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(isSelected ? .black.opacity(0.15) : AppColors.cardBackground)
                        )
                }
            }
            .foregroundColor(isSelected ? .black : AppColors.textPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isSelected ? AppColors.primary : AppColors.cardBackground)
                    .shadow(color: isSelected ? AppColors.primary.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 2)
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? Color.clear : AppColors.cardBorder,
                        lineWidth: 1
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
