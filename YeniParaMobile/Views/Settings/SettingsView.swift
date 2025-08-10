import SwiftUI

struct SettingsView: View {
    @ObservedObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var isDarkMode = true
    @State private var autoPlayVideos = true
    @State private var highQualityImages = false
    @State private var selectedLanguage = "Türkçe"
    @State private var selectedCurrency = "TRY"
    
    let languages = ["Türkçe", "English", "Deutsch", "Français"]
    let currencies = ["TRY", "USD", "EUR", "GBP"]
    
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
                    
                    Text("Ayarlar")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    // Placeholder for alignment
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .opacity(0)
                }
                .padding(.horizontal, AppConstants.screenPadding)
                .padding(.vertical, 16)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Görünüm Ayarları
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Görünüm")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal, AppConstants.screenPadding)
                            
                            VStack(spacing: 1) {
                                SettingToggleRow(
                                    icon: "moon.fill",
                                    title: "Karanlık Mod",
                                    subtitle: "Göz yorgunluğunu azaltır",
                                    isOn: $isDarkMode
                                )
                                
                                Divider()
                                    .background(AppColors.cardBorder)
                                    .padding(.leading, 60)
                                
                                SettingToggleRow(
                                    icon: "play.circle",
                                    title: "Videoları Otomatik Oynat",
                                    subtitle: "Veri kullanımını artırabilir",
                                    isOn: $autoPlayVideos
                                )
                                
                                Divider()
                                    .background(AppColors.cardBorder)
                                    .padding(.leading, 60)
                                
                                SettingToggleRow(
                                    icon: "photo",
                                    title: "Yüksek Kalite Görseller",
                                    subtitle: "Daha fazla veri kullanır",
                                    isOn: $highQualityImages
                                )
                            }
                            .background(AppColors.cardBackground)
                            .cornerRadius(AppConstants.cornerRadius)
                            .padding(.horizontal, AppConstants.screenPadding)
                        }
                        
                        // Dil ve Bölge
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Dil ve Bölge")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal, AppConstants.screenPadding)
                            
                            VStack(spacing: 1) {
                                SettingPickerRow(
                                    icon: "globe",
                                    title: "Dil",
                                    selection: $selectedLanguage,
                                    options: languages
                                )
                                
                                Divider()
                                    .background(AppColors.cardBorder)
                                    .padding(.leading, 60)
                                
                                SettingPickerRow(
                                    icon: "dollarsign.circle",
                                    title: "Para Birimi",
                                    selection: $selectedCurrency,
                                    options: currencies
                                )
                            }
                            .background(AppColors.cardBackground)
                            .cornerRadius(AppConstants.cornerRadius)
                            .padding(.horizontal, AppConstants.screenPadding)
                        }
                        
                        // Veri Kullanımı
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Veri ve Depolama")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal, AppConstants.screenPadding)
                            
                            VStack(spacing: 1) {
                                SettingActionRow(
                                    icon: "arrow.down.circle",
                                    title: "Önbelleği Temizle",
                                    subtitle: "254 MB",
                                    action: clearCache
                                )
                                
                                Divider()
                                    .background(AppColors.cardBorder)
                                    .padding(.leading, 60)
                                
                                SettingActionRow(
                                    icon: "chart.bar",
                                    title: "Veri Kullanımı",
                                    subtitle: "Bu ay: 1.2 GB",
                                    action: showDataUsage
                                )
                                
                                Divider()
                                    .background(AppColors.cardBorder)
                                    .padding(.leading, 60)
                                
                                SettingActionRow(
                                    icon: "arrow.down.doc",
                                    title: "İndirilenler",
                                    subtitle: "12 öğe",
                                    action: showDownloads
                                )
                            }
                            .background(AppColors.cardBackground)
                            .cornerRadius(AppConstants.cornerRadius)
                            .padding(.horizontal, AppConstants.screenPadding)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func clearCache() {
        // Cache temizleme işlemi
    }
    
    private func showDataUsage() {
        // Veri kullanımı detayları
    }
    
    private func showDownloads() {
        // İndirilenler listesi
    }
}

struct SettingToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppColors.primary)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppColors.primary)
        }
        .padding(.horizontal, AppConstants.screenPadding)
        .padding(.vertical, 12)
    }
}

struct SettingPickerRow: View {
    let icon: String
    let title: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppColors.primary)
                .frame(width: 28)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        selection = option
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selection)
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, AppConstants.screenPadding)
        .padding(.vertical, 12)
    }
}

struct SettingActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(AppColors.primary)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(.horizontal, AppConstants.screenPadding)
            .padding(.vertical, 12)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView(authVM: AuthViewModel())
        }
        .preferredColorScheme(.dark)
    }
}