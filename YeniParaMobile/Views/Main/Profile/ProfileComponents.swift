import SwiftUI

// MARK: - Account Info Card
struct AccountInfoCard: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hesap Tipi")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Text("Premium")
                        .font(.headline)
                        .foregroundColor(AppColors.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Üyelik Tarihi")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Text("15 Ocak 2024")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            
            Divider()
                .background(AppColors.cardBorder)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Yatırımcı Profili")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Text("Dengeli")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Spacer()
                
                Button("Güncelle") {
                    // Update profile
                }
                .font(.caption)
                .foregroundColor(AppColors.primary)
            }
        }
        .padding(20)
        .background(AppColors.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
}

// MARK: - Profile Menu Item
struct ProfileMenuItem: View {
    let icon: String
    let title: String
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: action ?? {}) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 30)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(AppColors.cardBackground)
            .cornerRadius(12)
        }
    }
}
