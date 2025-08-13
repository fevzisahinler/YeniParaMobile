import SwiftUI

struct NewsDetailView: View {
    let news: NewsItem
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Info
                    VStack(alignment: .leading, spacing: 12) {
                        // Symbol and Importance Badge
                        HStack(spacing: 12) {
                            // Symbol Badge
                            HStack(spacing: 6) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 12, weight: .semibold))
                                Text(news.symbolCode)
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppColors.primary)
                            )
                            
                            // Importance Level
                            Text(getImportanceText(news.importanceLevel))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(getImportanceColor(news.importanceLevel))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(getImportanceColor(news.importanceLevel).opacity(0.15))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(getImportanceColor(news.importanceLevel).opacity(0.3), lineWidth: 1)
                                        )
                                )
                            
                            Spacer()
                        }
                        
                        // Headline
                        Text(news.headline)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Meta Info
                        HStack(spacing: 16) {
                            // Author
                            HStack(spacing: 4) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 12))
                                Text(news.author)
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(AppColors.textSecondary)
                            
                            // Date
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 12))
                                Text(news.formattedDate)
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Divider()
                        .background(AppColors.cardBorder)
                        .padding(.horizontal, 20)
                    
                    // Sentiment Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Piyasa Etkisi")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        
                        HStack(spacing: 20) {
                            SentimentIndicator(
                                sentiment: news.sentiment,
                                isActive: true
                            )
                            
                            Spacer()
                            
                            // Affected Stocks
                            if !news.relatedSymbols.isEmpty {
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Etkilenen Hisseler")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(AppColors.textSecondary)
                                    
                                    HStack(spacing: 6) {
                                        ForEach(news.relatedSymbols.split(separator: ",").prefix(3), id: \.self) { symbol in
                                            Text(String(symbol).trimmingCharacters(in: .whitespaces))
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(AppColors.primary)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(AppColors.primary.opacity(0.1))
                                                )
                                                .onTapGesture {
                                                    dismiss()
                                                    navigationManager.navigateToStock(String(symbol).trimmingCharacters(in: .whitespaces))
                                                }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.cardBorder, lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Summary Section
                    if !news.summary.isEmpty && news.summary != " " {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Özet")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text(news.summary)
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textSecondary)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Open Original Article Button
                    Button(action: {
                        if let url = URL(string: news.url) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Text("Haberin Orijinalini Oku")
                                .font(.system(size: 15, weight: .semibold))
                            
                            Image(systemName: "arrow.up.forward.square")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.primary)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Related News Section (Optional - for future)
                    /*
                    VStack(alignment: .leading, spacing: 12) {
                        Text("İlgili Haberler")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, 20)
                        
                        // Related news cards here
                    }
                    */
                    
                    // Bottom Padding
                    Color.clear.frame(height: 40)
                }
            }
            .background(AppColors.background)
            .navigationTitle("Haber Detayı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                            .frame(width: 30, height: 30)
                            .background(
                                Circle()
                                    .fill(AppColors.cardBackground)
                            )
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Share functionality
                        shareNews()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                            .frame(width: 30, height: 30)
                            .background(
                                Circle()
                                    .fill(AppColors.cardBackground)
                            )
                    }
                }
            }
        }
    }
    
    private func getImportanceText(_ level: Int) -> String {
        switch level {
        case 5:
            return "Çok Önemli"
        case 4:
            return "Önemli"
        case 3:
            return "Normal"
        default:
            return "Düşük"
        }
    }
    
    private func getImportanceColor(_ level: Int) -> Color {
        switch level {
        case 5:
            return Color.red
        case 4:
            return Color.orange
        case 3:
            return Color.blue
        default:
            return Color.gray
        }
    }
    
    private func shareNews() {
        let text = "\(news.headline)\n\n\(news.url)"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Sentiment Indicator
struct SentimentIndicator: View {
    let sentiment: String
    let isActive: Bool
    
    var sentimentText: String {
        switch sentiment.lowercased() {
        case "positive", "bullish":
            return "Olumlu"
        case "negative", "bearish":
            return "Olumsuz"
        default:
            return "Nötr"
        }
    }
    
    var sentimentColor: Color {
        switch sentiment.lowercased() {
        case "positive", "bullish":
            return AppColors.success
        case "negative", "bearish":
            return AppColors.error
        default:
            return AppColors.textSecondary
        }
    }
    
    var sentimentIcon: String {
        switch sentiment.lowercased() {
        case "positive", "bullish":
            return "arrow.up.circle.fill"
        case "negative", "bearish":
            return "arrow.down.circle.fill"
        default:
            return "minus.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: sentimentIcon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(sentimentColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Piyasa Duyarlılığı")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                
                Text(sentimentText)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(sentimentColor)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(sentimentColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(sentimentColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}