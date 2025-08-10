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
                    
                    // Daily sentiment chart
                    if !sentiment.dailySentiments.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Günlük Dağılım")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Chart(sentiment.dailySentiments) { daily in
                                BarMark(
                                    x: .value("Tarih", formatDate(daily.date)),
                                    y: .value("Yorum", daily.bullishCount),
                                    stacking: .standard
                                )
                                .foregroundStyle(AppColors.primary)
                                .cornerRadius(4)
                                
                                BarMark(
                                    x: .value("Tarih", formatDate(daily.date)),
                                    y: .value("Yorum", daily.bearishCount),
                                    stacking: .standard
                                )
                                .foregroundStyle(AppColors.error)
                                .cornerRadius(4)
                                
                                BarMark(
                                    x: .value("Tarih", formatDate(daily.date)),
                                    y: .value("Yorum", daily.neutralCount),
                                    stacking: .standard
                                )
                                .foregroundStyle(AppColors.textSecondary)
                                .cornerRadius(4)
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading) { value in
                                    AxisValueLabel {
                                        if let intValue = value.as(Int.self) {
                                            Text("\(intValue)")
                                                .font(.caption2)
                                                .foregroundColor(AppColors.textTertiary)
                                        }
                                    }
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                        .foregroundStyle(AppColors.cardBorder)
                                }
                            }
                            .chartXAxis {
                                AxisMarks { _ in
                                    AxisValueLabel()
                                        .font(.caption2)
                                        .foregroundStyle(AppColors.textTertiary)
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                        .foregroundStyle(AppColors.cardBorder)
                                }
                            }
                            .frame(height: 150)
                            .padding(.vertical, 8)
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