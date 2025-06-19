import SwiftUI

// MARK: - Popular Topics Section
struct PopularTopicsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Popüler Konular")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(["Kripto", "Teknoloji", "Enerji", "Sağlık"], id: \.self) { topic in
                        Text(topic)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppColors.cardBackground)
                            .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Coming Soon Section
struct ComingSoonSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(AppColors.primary)
            
            Text("Yakında")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Topluluk özellikleri çok yakında aktif olacak!")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
