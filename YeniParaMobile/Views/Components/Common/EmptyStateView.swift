import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let icon: String
    
    init(title: String = "Henüz veri yok", message: String = "Veriler yükleniyor...", icon: String = "tray") {
        self.title = title
        self.message = message
        self.icon = icon
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(AppColors.textTertiary)
            
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
