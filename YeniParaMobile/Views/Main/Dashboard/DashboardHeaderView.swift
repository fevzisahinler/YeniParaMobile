import SwiftUI

struct DashboardHeaderView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hoş geldiniz!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Piyasaya genel bakış")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "bell")
                    .font(.title3)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(AppColors.cardBackground)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, AppConstants.screenPadding)
    }
}
