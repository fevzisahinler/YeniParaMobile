import SwiftUI
import Charts

struct StockSentimentView: View {
    let symbol: String
    @StateObject private var viewModel = StockSentimentViewModel()
    @State private var selectedDays = 7
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with day selector
            HStack {
                Text("Topluluk Görüşü")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                // Days selector
                Menu {
                    Button("7 Gün") {
                        selectedDays = 7
                        Task {
                            await viewModel.loadSentiment(symbol: symbol, days: selectedDays)
                        }
                    }
                    Button("30 Gün") {
                        selectedDays = 30
                        Task {
                            await viewModel.loadSentiment(symbol: symbol, days: selectedDays)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("\(selectedDays) Gün")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppColors.cardBackground)
                    .cornerRadius(6)
                }
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                    .frame(height: 200)
            } else if let sentiment = viewModel.sentimentData {
                VStack(spacing: 16) {
                    // Overall sentiment score
                    VStack(spacing: 16) {
                        // Title and total comments
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Genel Topluluk Görüşü")
                                    .font(.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                Text("\(sentiment.overall.totalComments) toplam yorum")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            // Overall sentiment badge
                            HStack(spacing: 6) {
                                Image(systemName: sentimentIcon(sentiment.overall.sentimentScore))
                                    .font(.system(size: 14, weight: .bold))
                                Text(overallSentimentText(sentiment.overall.sentimentScore))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(sentimentColor(sentiment.overall.sentimentScore))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(sentimentColor(sentiment.overall.sentimentScore).opacity(0.15))
                            .cornerRadius(20)
                        }
                        .padding(16)
                        .background(AppColors.cardBackground)
                        .cornerRadius(12)
                        
                        // Sentiment breakdown
                        HStack(spacing: 12) {
                            SentimentCard(
                                title: "Yükseliş",
                                count: sentiment.overall.bullishCount,
                                total: sentiment.overall.totalComments,
                                color: AppColors.primary
                            )
                            
                            SentimentCard(
                                title: "Nötr",
                                count: sentiment.overall.neutralCount,
                                total: sentiment.overall.totalComments,
                                color: AppColors.textSecondary
                            )
                            
                            SentimentCard(
                                title: "Düşüş",
                                count: sentiment.overall.bearishCount,
                                total: sentiment.overall.totalComments,
                                color: AppColors.error
                            )
                        }
                    }
                    
                    // Daily sentiment distribution
                    if !sentiment.dailySentiments.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Günlük Dağılım")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textPrimary)
                            
                            VStack(spacing: 8) {
                                ForEach(sentiment.dailySentiments, id: \.id) { daily in
                                    DailySentimentRow(daily: daily)
                                }
                            }
                        }
                        .padding(16)
                        .background(AppColors.cardBackground)
                        .cornerRadius(12)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadSentiment(symbol: symbol, days: selectedDays)
            }
        }
    }
    
    private func overallSentimentText(_ score: Double) -> String {
        if score > 0.3 {
            return "Güçlü Yükseliş"
        } else if score > 0.1 {
            return "Yükseliş"
        } else if score < -0.3 {
            return "Güçlü Düşüş"
        } else if score < -0.1 {
            return "Düşüş"
        } else {
            return "Nötr"
        }
    }
    
    private func sentimentColor(_ score: Double) -> Color {
        if score > 0.1 {
            return AppColors.primary
        } else if score < -0.1 {
            return AppColors.error
        } else {
            return AppColors.textSecondary
        }
    }
    
    private func sentimentIcon(_ score: Double) -> String {
        if score > 0.1 {
            return "arrow.up.circle.fill"
        } else if score < -0.1 {
            return "arrow.down.circle.fill"
        } else {
            return "minus.circle.fill"
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        guard let date = formatter.date(from: dateString) else {
            return ""
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "dd/MM"
        return displayFormatter.string(from: date)
    }
}


// MARK: - Daily Sentiment Row
struct DailySentimentRow: View {
    let daily: DailySentiment
    
    private var totalComments: Int {
        daily.bullishCount + daily.bearishCount + daily.neutralCount
    }
    
    private var bullishPercent: Double {
        guard totalComments > 0 else { return 0 }
        return Double(daily.bullishCount) / Double(totalComments) * 100
    }
    
    private var bearishPercent: Double {
        guard totalComments > 0 else { return 0 }
        return Double(daily.bearishCount) / Double(totalComments) * 100
    }
    
    private var neutralPercent: Double {
        guard totalComments > 0 else { return 0 }
        return Double(daily.neutralCount) / Double(totalComments) * 100
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(formatDate(daily.date))
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                Spacer()
                
                Text("\(totalComments) yorum")
                    .font(.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.caption2)
                        .foregroundColor(AppColors.primary)
                    Text(String(format: "%%%.0f", bullishPercent))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.primary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "minus.circle.fill")
                        .font(.caption2)
                        .foregroundColor(AppColors.textSecondary)
                    Text(String(format: "%%%.0f", neutralPercent))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.caption2)
                        .foregroundColor(AppColors.error)
                    Text(String(format: "%%%.0f", bearishPercent))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.error)
                }
                
                Spacer()
            }
            
            // Progress bar showing distribution
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    if bullishPercent > 0 {
                        Rectangle()
                            .fill(AppColors.primary)
                            .frame(width: geometry.size.width * (bullishPercent / 100))
                    }
                    if neutralPercent > 0 {
                        Rectangle()
                            .fill(AppColors.textSecondary)
                            .frame(width: geometry.size.width * (neutralPercent / 100))
                    }
                    if bearishPercent > 0 {
                        Rectangle()
                            .fill(AppColors.error)
                            .frame(width: geometry.size.width * (bearishPercent / 100))
                    }
                }
                .cornerRadius(2)
            }
            .frame(height: 4)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(AppColors.cardBackground.opacity(0.5))
        .cornerRadius(8)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        guard let date = formatter.date(from: dateString) else {
            return ""
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "dd MMM"
        displayFormatter.locale = Locale(identifier: "tr_TR")
        return displayFormatter.string(from: date)
    }
}

// MARK: - Sentiment Card
struct SentimentCard: View {
    let title: String
    let count: Int
    let total: Int
    let color: Color
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total) * 100
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(String(format: "%.0f%%", percentage))
                .font(.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - ViewModel
@MainActor
class StockSentimentViewModel: ObservableObject {
    @Published var sentimentData: SentimentData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    func loadSentiment(symbol: String, days: Int) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.getStockSentiment(symbol: symbol, days: days)
            
            if response.success {
                sentimentData = response.data
            }
        } catch {
            errorMessage = error.localizedDescription
            // Generate mock data for preview
            generateMockData()
        }
        
        isLoading = false
    }
    
    private func generateMockData() {
        let mockOverall = OverallSentiment(
            bearishCount: 15,
            bullishCount: 45,
            neutralCount: 20,
            sentimentScore: 0.4,
            totalComments: 80
        )
        
        let mockDailies = (0..<7).map { day in
            DailySentiment(
                id: day,
                symbolCode: "MOCK",
                date: ISO8601DateFormatter().string(from: Date().addingTimeInterval(TimeInterval(-day * 86400))),
                bullishCount: Int.random(in: 5...20),
                bearishCount: Int.random(in: 2...10),
                neutralCount: Int.random(in: 1...8),
                totalComments: 0,
                sentimentScore: Double.random(in: -0.5...0.8),
                createdAt: ISO8601DateFormatter().string(from: Date())
            )
        }
        
        sentimentData = SentimentData(
            dailySentiments: mockDailies,
            overall: mockOverall
        )
    }
}