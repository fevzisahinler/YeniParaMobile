import SwiftUI

struct ValidationItem {
    let title: String
    let isValid: Bool
    let icon: String
}

struct ValidationItemView: View {
    let item: ValidationItem
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: item.icon)
                .font(.system(size: 12))
                .foregroundColor(item.isValid ? AppColors.primary : Color.white.opacity(0.3))
            
            Text(item.title)
                .font(.system(size: 11))
                .foregroundColor(item.isValid ? Color.white.opacity(0.8) : Color.white.opacity(0.4))
        }
    }
}
