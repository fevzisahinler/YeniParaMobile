import SwiftUI
import Charts

struct SymbolDetailView: View {
    let symbol: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var candles: [CandleData] = []
    @State private var isLoading = false
    @State private var selectedChartType: ChartType = .line
    @State private var currentPrice: Double = 0
    @State private var priceChange: Double = 0
    @State private var priceChangePercent: Double = 0
    @State private var volume24h: Double = 0
    @State private var high24h: Double = 0
    @State private var low24h: Double = 0
    @State private var openPrice: Double = 0
    @State private var marketCap: String = "N/A"
    @State private var isInWatchlist: Bool = false
    
    private var isPositiveChange: Bool { priceChange >= 0 }
    private var changeColor: Color {
        isPositiveChange ? AppColors.primary : AppColors.error
    }
    
    private var companyName: String {
        getCompanyName(for: symbol)
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Navigation Bar
                customNavigationBar
                
                if isLoading {
                    LoadingView(message: "Hisse verileri yükleniyor...")
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header with price info
                            headerSection
                            
                            // Chart controls
                            chartControlsSection
                            
                            // Main chart
                            chartSection
                            
                            // Statistics section
                            statisticsSection
                            
                            // Market info
                            marketInfoSection
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadSampleData()
        }
    }
    
    // MARK: - Custom Navigation Bar
    private var customNavigationBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(symbol)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(companyName)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: { isInWatchlist.toggle() }) {
                    Image(systemName: isInWatchlist ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundColor(isInWatchlist ? AppColors.error : AppColors.textPrimary)
                        .frame(width: 44, height: 44)
                }
                
                Button(action: { }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 44, height: 44)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppColors.background)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.secondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(String(symbol.prefix(2)))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.textPrimary)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(symbol)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("NASDAQ")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(AppColors.primary)
                        .frame(width: 8, height: 8)
                    
                    Text("CANLI")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppColors.primary.opacity(0.2))
                .cornerRadius(12)
            }
            
            // Price information
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("$\(String(format: "%.2f", currentPrice))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: isPositiveChange ? "triangle.fill" : "triangle.fill")
                                .font(.caption)
                                .rotationEffect(.degrees(isPositiveChange ? 0 : 180))
                                .foregroundColor(changeColor)
                            
                            Text("\(isPositiveChange ? "+" : "")$\(String(format: "%.2f", priceChange))")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(changeColor)
                        }
                        
                        Text("\(isPositiveChange ? "+" : "")\(String(format: "%.2f", priceChangePercent))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(changeColor)
                    }
                }
                
                // Quick stats
                HStack(spacing: 20) {
                    StatItem(title: "Açılış", value: "$\(String(format: "%.2f", openPrice))", color: AppColors.textSecondary)
                    StatItem(title: "Günlük Yüksek", value: "$\(String(format: "%.2f", high24h))", color: AppColors.textSecondary)
                    StatItem(title: "Günlük Düşük", value: "$\(String(format: "%.2f", low24h))", color: AppColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, AppConstants.screenPadding)
    }
    
    // MARK: - Chart Controls Section
    private var chartControlsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Grafik Türü")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text("1 Günlük Veri")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            HStack(spacing: 12) {
                ForEach(ChartType.allCases, id: \.rawValue) { chartType in
                    Button(action: {
                        selectedChartType = chartType
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: chartType.icon)
                                .font(.caption)
                            Text(chartType.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(selectedChartType == chartType ? .black : AppColors.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedChartType == chartType
                                ? AppColors.primary
                                : AppColors.cardBackground
                        )
                        .cornerRadius(20)
                    }
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, AppConstants.screenPadding)
    }
    
    // MARK: - Chart Section
    private var chartSection: some View {
        VStack(spacing: 12) {
            if candles.isEmpty {
                Text("Grafik verisi yükleniyor...")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(height: 300)
            } else {
                Chart(candles) { candle in
                    if selectedChartType == .line {
                        LineMark(
                            x: .value("Tarih", candle.timestamp),
                            y: .value("Kapanış", candle.close)
                        )
                        .foregroundStyle(AppColors.primary)
                        .interpolationMethod(.catmullRom)
                    } else {
                        AreaMark(
                            x: .value("Tarih", candle.timestamp),
                            y: .value("Kapanış", candle.close)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    AppColors.primary.opacity(0.6),
                                    AppColors.primary.opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(AppColors.cardBorder)
                        AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(AppColors.textTertiary)
                        AxisValueLabel()
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(AppColors.cardBorder)
                        AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(AppColors.textTertiary)
                        AxisValueLabel()
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                .frame(height: 300)
                .padding(.horizontal, AppConstants.screenPadding)
            }
        }
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("İstatistikler")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(title: "Hacim", value: String(format: "%.1fM", volume24h / 1_000_000))
                StatCard(title: "Piyasa Değeri", value: marketCap)
                StatCard(title: "P/E Oranı", value: "24.5")
                StatCard(title: "52H Yüksek", value: "$\(String(format: "%.2f", high24h * 1.2))")
                StatCard(title: "52H Düşük", value: "$\(String(format: "%.2f", low24h * 0.8))")
                StatCard(title: "Beta", value: "1.2")
            }
        }
        .padding(.horizontal, AppConstants.screenPadding)
    }
    
    // MARK: - Market Info Section
    private var marketInfoSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Hakkında")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            
            VStack(spacing: 12) {
                InfoRow(title: "Şirket Adı", value: companyName)
                InfoRow(title: "Sektör", value: "Teknoloji")
                InfoRow(title: "Borsa", value: "NASDAQ")
                InfoRow(title: "Ülke", value: "ABD")
                InfoRow(title: "Para Birimi", value: "USD")
            }
        }
        .padding(.horizontal, AppConstants.screenPadding)
    }
    
    private func loadSampleData() {
        isLoading = true
        
        // Sample data
        currentPrice = 175.23
        priceChange = 4.12
        priceChangePercent = 2.45
        openPrice = 171.11
        high24h = 178.45
        low24h = 172.10
        volume24h = 45_200_000
        marketCap = "2.8T"
        
        // Sample chart data
        let calendar = Calendar.current
        let now = Date()
        
        candles = (0..<30).compactMap { i in
            guard let date = calendar.date(byAdding: .day, value: -i, to: now) else { return nil }
            let basePrice = 170.0 + Double.random(in: -10...10)
            return CandleData(
                timestamp: date,
                open: basePrice,
                high: basePrice + Double.random(in: 0...5),
                low: basePrice - Double.random(in: 0...5),
                close: basePrice + Double.random(in: -3...3),
                volume: Double.random(in: 20_000_000...50_000_000)
            )
        }.reversed()
        
        isLoading = false
    }
    
    private func getCompanyName(for symbol: String) -> String {
        let companyNames: [String: String] = [
            "AAPL": "Apple Inc.",
            "MSFT": "Microsoft Corp.",
            "GOOGL": "Alphabet Inc.",
            "TSLA": "Tesla Inc.",
            "AMZN": "Amazon.com Inc."
        ]
        return companyNames[symbol] ?? symbol
    }
}

enum ChartType: String, CaseIterable {
    case line = "line"
    case area = "area"
    
    var displayName: String {
        switch self {
        case .line: return "Çizgi"
        case .area: return "Alan"
        }
    }
    
    var icon: String {
        switch self {
        case .line: return "chart.line.uptrend.xyaxis"
        case .area: return "chart.area"
        }
    }
}

struct SymbolDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SymbolDetailView(symbol: "AAPL")
        }
        .preferredColorScheme(.dark)
    }
}
