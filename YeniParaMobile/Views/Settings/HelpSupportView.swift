import SwiftUI

struct HelpSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: FAQCategory = .general
    @State private var expandedFAQ: String? = nil
    
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
                    
                    Text("Yardım & Destek")
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
                    VStack(spacing: 24) {
                        // Arama Kutusu
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppColors.textSecondary)
                            
                            TextField("Nasıl yardımcı olabiliriz?", text: $searchText)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .padding(12)
                        .background(AppColors.cardBackground)
                        .cornerRadius(AppConstants.cornerRadius)
                        .padding(.horizontal, AppConstants.screenPadding)
                        
                        // Hızlı Yardım Kartları
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                QuickHelpCard(
                                    icon: "doc.text",
                                    title: "Kullanım Kılavuzu",
                                    color: Color.blue
                                )
                                
                                QuickHelpCard(
                                    icon: "play.circle",
                                    title: "Video Rehberler",
                                    color: Color.purple
                                )
                                
                                QuickHelpCard(
                                    icon: "questionmark.circle",
                                    title: "SSS",
                                    color: Color.orange
                                )
                            }
                            .padding(.horizontal, AppConstants.screenPadding)
                        }
                        
                        // İletişim Seçenekleri
                        VStack(alignment: .leading, spacing: 16) {
                            Text("İletişim")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal, AppConstants.screenPadding)
                            
                            VStack(spacing: 1) {
                                ContactOptionRow(
                                    icon: "message.circle.fill",
                                    title: "Canlı Destek",
                                    subtitle: "7/24 online destek",
                                    badgeText: "Çevrimiçi",
                                    badgeColor: AppColors.primary
                                )
                                
                                Divider()
                                    .background(AppColors.cardBorder)
                                    .padding(.leading, 60)
                                
                                ContactOptionRow(
                                    icon: "envelope.circle.fill",
                                    title: "E-posta",
                                    subtitle: "destek@yenipara.com",
                                    badgeText: nil,
                                    badgeColor: .clear
                                )
                                
                                Divider()
                                    .background(AppColors.cardBorder)
                                    .padding(.leading, 60)
                                
                                ContactOptionRow(
                                    icon: "phone.circle.fill",
                                    title: "Telefon",
                                    subtitle: "0850 123 45 67",
                                    badgeText: "09:00-18:00",
                                    badgeColor: Color.gray
                                )
                            }
                            .background(AppColors.cardBackground)
                            .cornerRadius(AppConstants.cornerRadius)
                            .padding(.horizontal, AppConstants.screenPadding)
                        }
                        
                        // SSS Kategorileri
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Sıkça Sorulan Sorular")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal, AppConstants.screenPadding)
                            
                            // Kategori Seçici
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(FAQCategory.allCases, id: \.self) { category in
                                        CategoryChip(
                                            title: category.title,
                                            isSelected: selectedCategory == category
                                        ) {
                                            selectedCategory = category
                                        }
                                    }
                                }
                                .padding(.horizontal, AppConstants.screenPadding)
                            }
                            
                            // SSS Listesi
                            VStack(spacing: 8) {
                                ForEach(getFAQs(for: selectedCategory), id: \.question) { faq in
                                    FAQItem(
                                        question: faq.question,
                                        answer: faq.answer,
                                        isExpanded: expandedFAQ == faq.question
                                    ) {
                                        withAnimation {
                                            if expandedFAQ == faq.question {
                                                expandedFAQ = nil
                                            } else {
                                                expandedFAQ = faq.question
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, AppConstants.screenPadding)
                        }
                        
                        // Geri Bildirim
                        FeedbackCard()
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    func getFAQs(for category: FAQCategory) -> [FAQ] {
        switch category {
        case .general:
            return [
                FAQ(question: "YeniPara nedir?", answer: "YeniPara, hisse senedi takibi ve yatırım analizi yapmanızı sağlayan mobil uygulamadır."),
                FAQ(question: "Üyelik ücretsiz mi?", answer: "Evet, temel özellikler ücretsizdir. Premium özellikler için aylık abonelik seçenekleri mevcuttur."),
                FAQ(question: "Hangi piyasaları takip edebilirim?", answer: "SP100 hisselerini ve major endeksleri takip edebilirsiniz.")
            ]
        case .account:
            return [
                FAQ(question: "Şifremi nasıl değiştirebilirim?", answer: "Profil > Güvenlik > Şifreyi Değiştir yolunu takip ederek şifrenizi güncelleyebilirsiniz."),
                FAQ(question: "Hesabımı nasıl silerim?", answer: "Ayarlar > Hesap > Hesabı Sil seçeneğinden hesabınızı kalıcı olarak silebilirsiniz."),
                FAQ(question: "E-posta adresimi değiştirebilir miyim?", answer: "Evet, Profil > Ayarlar bölümünden e-posta adresinizi güncelleyebilirsiniz.")
            ]
        case .trading:
            return [
                FAQ(question: "Gerçek zamanlı fiyatlar mı?", answer: "Fiyatlar 15 dakika gecikmeli olarak gösterilir. Premium üyelik ile gerçek zamanlı fiyatlara erişebilirsiniz."),
                FAQ(question: "Alım satım yapabilir miyim?", answer: "Şu anda sadece takip özelliği mevcuttur. İleride alım satım özelliği eklenecektir."),
                FAQ(question: "Teknik analiz araçları var mı?", answer: "Evet, temel teknik göstergeler ve grafik araçları mevcuttur.")
            ]
        case .technical:
            return [
                FAQ(question: "Uygulama çöküyor", answer: "Uygulamayı güncelleyin ve cihazınızı yeniden başlatın. Sorun devam ederse destek ekibimizle iletişime geçin."),
                FAQ(question: "Bildirimler gelmiyor", answer: "Ayarlar > Bildirimler bölümünden bildirimlerin açık olduğundan emin olun."),
                FAQ(question: "Grafik yüklenmiyor", answer: "İnternet bağlantınızı kontrol edin ve uygulamayı yeniden başlatın.")
            ]
        }
    }
}

enum FAQCategory: CaseIterable {
    case general, account, trading, technical
    
    var title: String {
        switch self {
        case .general: return "Genel"
        case .account: return "Hesap"
        case .trading: return "İşlemler"
        case .technical: return "Teknik"
        }
    }
}

struct FAQ {
    let question: String
    let answer: String
}

struct QuickHelpCard: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 100, height: 100)
        .background(AppColors.cardBackground)
        .cornerRadius(AppConstants.cornerRadius)
    }
}

struct ContactOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let badgeText: String?
    let badgeColor: Color
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(AppColors.primary)
                    .frame(width: 32)
                
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
                
                if let badgeText = badgeText {
                    Text(badgeText)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(badgeColor)
                        .cornerRadius(8)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(.horizontal, AppConstants.screenPadding)
            .padding(.vertical, 12)
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : AppColors.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppColors.primary : AppColors.cardBackground)
                .cornerRadius(20)
        }
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    let isExpanded: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                if isExpanded {
                    Text(answer)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(AppConstants.cardPadding)
            .background(AppColors.cardBackground)
            .cornerRadius(AppConstants.cornerRadius)
        }
    }
}

struct FeedbackCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.bubble")
                .font(.title)
                .foregroundColor(AppColors.primary)
            
            Text("Geri Bildiriminiz Bizim İçin Önemli")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Uygulamamızı geliştirmemize yardımcı olun")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            
            Button(action: {}) {
                Text("Geri Bildirim Gönder")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppColors.primary)
                    .cornerRadius(20)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    AppColors.cardBackground,
                    AppColors.primary.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(AppConstants.cornerRadius)
        .padding(.horizontal, AppConstants.screenPadding)
    }
}

struct HelpSupportView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HelpSupportView()
        }
        .preferredColorScheme(.dark)
    }
}