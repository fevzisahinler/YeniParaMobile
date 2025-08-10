import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    Spacer()
                    
                    Text("Hakkında")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .opacity(0)
                }
                .padding(.horizontal, AppConstants.screenPadding)
                .padding(.vertical, 16)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Logo ve Versiyon
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [AppColors.primary, AppColors.secondary],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                
                                Text("YP")
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 8) {
                                Text("YeniPara")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Text("Versiyon 1.0.0")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.textSecondary)
                                
                                Text("Build 2024.1.15")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textTertiary)
                            }
                        }
                        
                        // Açıklama
                        VStack(spacing: 16) {
                            Text("Yatırımınızın Geleceği")
                                .font(.headline)
                                .foregroundColor(AppColors.primary)
                            
                            Text("YeniPara, yatırımcıların piyasaları takip etmesini, analiz yapmasını ve bilinçli yatırım kararları almasını sağlayan yenilikçi bir mobil uygulamadır.")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        
                        // Özellikler
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Özellikler")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            VStack(spacing: 12) {
                                FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Gerçek zamanlı piyasa verileri")
                                FeatureRow(icon: "star", text: "Kişiselleştirilmiş izleme listeleri")
                                FeatureRow(icon: "bell", text: "Akıllı fiyat uyarıları")
                                FeatureRow(icon: "chart.bar", text: "Detaylı teknik analiz")
                                FeatureRow(icon: "newspaper", text: "Güncel piyasa haberleri")
                                FeatureRow(icon: "person.3", text: "Yatırımcı topluluğu")
                            }
                        }
                        .padding(.horizontal, AppConstants.screenPadding)
                        
                        // Ekip
                        VStack(spacing: 16) {
                            Text("Ekibimiz")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("YeniPara, finans ve teknoloji alanında uzman bir ekip tarafından geliştirilmektedir.")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        
                        // Sosyal Medya
                        VStack(spacing: 16) {
                            Text("Bizi Takip Edin")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            HStack(spacing: 24) {
                                SocialMediaButton(icon: "link", platform: "Web")
                                SocialMediaButton(icon: "envelope", platform: "Mail")
                                SocialMediaButton(icon: "message", platform: "Twitter")
                                SocialMediaButton(icon: "camera", platform: "Instagram")
                            }
                        }
                        
                        // Yasal
                        VStack(spacing: 12) {
                            Button(action: {}) {
                                HStack {
                                    Text("Kullanım Koşulları")
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.primary)
                                    
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundColor(AppColors.primary)
                                }
                            }
                            
                            Button(action: {}) {
                                HStack {
                                    Text("Gizlilik Politikası")
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.primary)
                                    
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundColor(AppColors.primary)
                                }
                            }
                            
                            Button(action: {}) {
                                HStack {
                                    Text("Lisanslar")
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.primary)
                                    
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundColor(AppColors.primary)
                                }
                            }
                        }
                        
                        // Copyright
                        VStack(spacing: 8) {
                            Text("© 2024 YeniPara")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                            
                            Text("Tüm hakları saklıdır.")
                                .font(.caption)
                                .foregroundColor(AppColors.textTertiary)
                            
                            Text("Made with ❤️ in Istanbul")
                                .font(.caption)
                                .foregroundColor(AppColors.textTertiary)
                        }
                        .padding(.bottom, 20)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 30)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppColors.primary)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, AppConstants.screenPadding)
    }
}

struct SocialMediaButton: View {
    let icon: String
    let platform: String
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(AppColors.cardBackground)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(AppColors.primary)
                }
                
                Text(platform)
                    .font(.caption2)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AboutView()
        }
        .preferredColorScheme(.dark)
    }
}