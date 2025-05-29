import SwiftUI
import Charts

struct SymbolDetailView: View {
    let symbol: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var candles: [CandleData] = []
    @State private var isLoading = true
    @State private var selectedChartType: ChartType = .line
    @State private var selectedTimeframe: TimeFrame = .oneDay
    @State private var currentPrice: Double = 0
    @State private var priceChange: Double = 0
    @State private var priceChangePercent: Double = 0
    @State private var volume24h: Double = 0
    @State private var high24h: Double = 0
    @State private var low24h: Double = 0
    @State private var openPrice: Double = 0
    @State private var marketCap: String = "N/A"
    @State private var isInWatchlist: Bool = false
    @State private var showingShareSheet = false
    @State private var errorMessage: String?
    
    private var isPositiveChange: Bool { priceChange >= 0 }
    private var changeColor: Color {
        isPositiveChange ? AppColors.primary : AppColors.error
    }
    
    private var companyName: String {
        getCompanyName(for: symbol)
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Navigation Bar
                    customNavigationBar
                    
                    if isLoading {
                        LoadingView(message: "Hisse verileri yükleniyor...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = errorMessage {
                        ErrorView(message: error) {
                            loadData()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack(spacing: 24) {
                                // Header with price info
                                headerSection
                                
                                // Chart controls
                                chartControlsSection
                                
                                // Main chart
                                chartSection
                                
                                // Quick stats
                                quickStatsSection
                                
                                // Statistics section
                                statisticsSection
                                
                                // Market info
                                marketInfoSection
                                
                                // Action buttons
                                actionButtonsSection
                            }
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .navigationViewStyle(StackNavigationViewStyle()) // Force single view navigation
        .onAppear {
            loadData()
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [createShareText()])
        }
    }
    
    // MARK: - Custom Navigation Bar
    private var customNavigationBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Geri")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(AppColors.textPrimary)
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
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        isInWatchlist.toggle()
                    }
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }) {
                    Image(systemName: isInWatchlist ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(isInWatchlist ? AppColors.error : AppColors.textPrimary)
                }
                
                Button(action: { showingShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .padding(.horizontal, AppConstants.screenPadding)
        .padding(.vertical, 12)
        .background(AppColors.background)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 12) {
                        // Company Logo
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [AppColors.primary, AppColors.secondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)
                            
                            Text(String(symbol.prefix(2)))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(symbol)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("NASDAQ • USD")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                // Live indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(AppColors.primary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isLoading ? 1.0 : 1.2)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isLoading)
                    
                    Text("CANLI")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppColors.primary.opacity(0.15))
                .cornerRadius(12)
            }
            
            // Price information
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Text(formatPrice(currentPrice))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: isPositiveChange ? "triangle.fill" : "triangle.fill")
                                .font(.system(size: 12, weight: .bold))
                                .rotationEffect(.degrees(isPositiveChange ? 0 : 180))
                                .foregroundColor(changeColor)
                            
                            Text(formatChange(priceChange))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(changeColor)
                        }
                        
                        Text(formatChangePercent(priceChangePercent))
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(changeColor)
                    }
                }
            }
        }
        .padding(.horizontal, AppConstants.screenPadding)
    }
    
    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        HStack(spacing: 16) {
            QuickStatItem(title: "Açılış", value: formatPrice(openPrice))
            QuickStatItem(title: "Yüksek", value: formatPrice(high24h))
            QuickStatItem(title: "Düşük", value: formatPrice(low24h))
            QuickStatItem(title: "Hacim", value: formatVolume(volume24h))
        }
        .padding(.horizontal, AppConstants.screenPadding)
    }
    
    // MARK: - Chart Controls Section
    private var chartControlsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Grafik")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text(selectedTimeframe.displayName)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.cardBackground)
                    .cornerRadius(8)
            }
            
            // Chart type selector
            HStack(spacing: 12) {
                ForEach(ChartType.allCases, id: \.rawValue) { chartType in
                    ChartTypeButton(
                        type: chartType,
                        isSelected: selectedChartType == chartType
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedChartType = chartType
                        }
                    }
                }
                
                Spacer()
            }
            
            // Timeframe selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TimeFrame.allCases, id: \.rawValue) { timeframe in
                        TimeFrameButton(
                            timeframe: timeframe,
                            isSelected: selectedTimeframe == timeframe
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTimeframe = timeframe
                                loadChartData()
                            }
                        }
                    }
                }
                .padding(.horizontal, AppConstants.screenPadding)
            }
        }
        .padding(.horizontal, AppConstants.screenPadding)
    }
    
    // MARK: - Chart Section
    private var chartSection: some View {
        VStack(spacing: 16) {
            if candles.isEmpty {
                RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                    .fill(AppColors.cardBackground)
                    .frame(height: 300)
                    .overlay(
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                                .scaleEffect(1.2)
                            Text("Grafik yükleniyor...")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    )
            } else {
                Chart(candles) { candle in
                    if selectedChartType == .line {
                        LineMark(
                            x: .value("Tarih", candle.timestamp),
                            y: .value("Kapanış", candle.close)
                        )
                        .foregroundStyle(AppColors.primary)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)
                    } else if selectedChartType == .area {
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
                    } else {
                        // Candlestick chart
                        RectangleMark(
                            x: .value("Tarih", candle.timestamp),
                            yStart: .value("Düşük", min(candle.open, candle.close)),
                            yEnd: .value("Yüksek", max(candle.open, candle.close))
                        )
                        .foregroundStyle(candle.close >= candle.open ? AppColors.primary : AppColors.error)
                        .opacity(0.8)
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
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                        .fill(AppColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                                .stroke(AppColors.cardBorder, lineWidth: 1)
                        )
                )
            }
        }
        .padding(.horizontal, AppConstants.screenPadding)
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Detaylar")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(title: "Piyasa Değeri", value: marketCap)
                StatCard(title: "P/E Oranı", value: "24.5")
                StatCard(title: "52H Yüksek", value: formatPrice(high24h * 1.2))
                StatCard(title: "52H Düşük", value: formatPrice(low24h * 0.8))
                StatCard(title: "Beta", value: "1.2")
                StatCard(title: "Temettü", value: "2.1%")
            }
        }
        .padding(.horizontal, AppConstants.screenPadding)
    }
    
    // MARK: - Market Info Section
    private var marketInfoSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Şirket Bilgileri")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            
            VStack(spacing: 0) {
                InfoRow(title: "Şirket Adı", value: companyName)
                Divider().background(AppColors.cardBorder)
                InfoRow(title: "Sektör", value: getSector(for: symbol))
                Divider().background(AppColors.cardBorder)
                InfoRow(title: "Borsa", value: "NASDAQ")
                Divider().background(AppColors.cardBorder)
                InfoRow(title: "Ülke", value: "ABD")
                Divider().background(AppColors.cardBorder)
                InfoRow(title: "Para Birimi", value: "USD")
            }
            .padding(AppConstants.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                    .fill(AppColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                            .stroke(AppColors.cardBorder, lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, AppConstants.screenPadding)
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Button(action: {
                    // Buy action
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("Satın Al")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.primary)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    // Sell action
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 16))
                        Text("Sat")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.cardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.cardBorder, lineWidth: 1)
                    )
                }
            }
            
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isInWatchlist.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: isInWatchlist ? "heart.fill" : "heart")
                        .font(.system(size: 16))
                    Text(isInWatchlist ? "İzleme Listesinden Çıkar" : "İzleme Listesine Ekle")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(isInWatchlist ? AppColors.error : AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColors.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isInWatchlist ? AppColors.error : AppColors.cardBorder, lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, AppConstants.screenPadding)
    }
    
    // MARK: - Helper Functions
    private func loadData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Simulate API call
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                await MainActor.run {
                    // Sample data
                    currentPrice = Double.random(in: 150...200)
                    priceChange = Double.random(in: -10...10)
                    priceChangePercent = (priceChange / currentPrice) * 100
                    openPrice = currentPrice - priceChange + Double.random(in: -5...5)
                    high24h = currentPrice + Double.random(in: 0...10)
                    low24h = currentPrice - Double.random(in: 0...10)
                    volume24h = Double.random(in: 20_000_000...50_000_000)
                    marketCap = formatMarketCap(currentPrice * 1_000_000_000)
                    
                    loadChartData()
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Veri yüklenirken hata oluştu"
                    isLoading = false
                }
            }
        }
    }
    
    private func loadChartData() {
        let calendar = Calendar.current
        let now = Date()
        let dataPoints = selectedTimeframe.dataPoints
        
        candles = (0..<dataPoints).compactMap { i in
            guard let date = calendar.date(byAdding: selectedTimeframe.dateComponent, value: -i, to: now) else { return nil }
            let basePrice = currentPrice + Double.random(in: -20...20)
            let open = basePrice + Double.random(in: -2...2)
            let close = basePrice + Double.random(in: -2...2)
            let high = max(open, close) + Double.random(in: 0...3)
            let low = min(open, close) - Double.random(in: 0...3)
            
            return CandleData(
                timestamp: date,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: Double.random(in: 10_000_000...30_000_000)
            )
        }.reversed()
    }
    
    private func formatPrice(_ price: Double) -> String {
        if price == 0 { return "N/A" }
        return "$\(String(format: "%.2f", price))"
    }
    
    private func formatChange(_ change: Double) -> String {
        if change == 0 { return "$0.00" }
        return "\(change >= 0 ? "+" : "")$\(String(format: "%.2f", change))"
    }
    
    private func formatChangePercent(_ percent: Double) -> String {
        if percent == 0 { return "0.00%" }
        return "\(percent >= 0 ? "+" : "")\(String(format: "%.2f", percent))%"
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1_000_000 {
            return String(format: "%.1fM", volume / 1_000_000)
        } else if volume >= 1_000 {
            return String(format: "%.0fK", volume / 1_000)
        } else {
            return String(format: "%.0f", volume)
        }
    }
    
    private func formatMarketCap(_ marketCap: Double) -> String {
        if marketCap >= 1_000_000_000_000 {
            return String(format: "%.1fT", marketCap / 1_000_000_000_000)
        } else if marketCap >= 1_000_000_000 {
            return String(format: "%.1fB", marketCap / 1_000_000_000)
        } else if marketCap >= 1_000_000 {
            return String(format: "%.1fM", marketCap / 1_000_000)
        } else {
            return String(format: "%.0f", marketCap)
        }
    }
    
    private func getCompanyName(for symbol: String) -> String {
        let companyNames: [String: String] = [
            "AAPL": "Apple Inc.",
            "MSFT": "Microsoft Corp.",
            "GOOGL": "Alphabet Inc.",
            "TSLA": "Tesla Inc.",
            "AMZN": "Amazon.com Inc.",
            "META": "Meta Platforms Inc.",
            "NVDA": "NVIDIA Corp.",
            "NFLX": "Netflix Inc."
        ]
        return companyNames[symbol] ?? "\(symbol) Inc."
    }
    
    private func getSector(for symbol: String) -> String {
        let sectors: [String: String] = [
            "AAPL": "Teknoloji",
            "MSFT": "Teknoloji",
            "GOOGL": "Teknoloji",
            "TSLA": "Otomobil",
            "AMZN": "E-ticaret",
            "META": "Sosyal Medya",
            "NVDA": "Yarı İletken",
            "NFLX": "Medya"
        ]
        return sectors[symbol] ?? "Teknoloji"
    }
    
    private func createShareText() -> String {
        return "\(symbol) - \(formatPrice(currentPrice)) (\(formatChangePercent(priceChangePercent))) - YeniPara'dan paylaşıldı"
    }
}

// MARK: - Supporting Views
struct QuickStatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppColors.cardBackground)
        .cornerRadius(8)
    }
}

struct ChartTypeButton: View {
    let type: ChartType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.caption)
                Text(type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .black : AppColors.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? AppColors.primary : AppColors.cardBackground)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : AppColors.cardBorder, lineWidth: 1)
            )
        }
    }
}

struct TimeFrameButton: View {
    let timeframe: TimeFrame
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(timeframe.shortName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .black : AppColors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppColors.primary : AppColors.cardBackground)
                .cornerRadius(8)
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Supporting Types
enum ChartType: String, CaseIterable {
    case line = "line"
    case area = "area"
    case candlestick = "candlestick"
    
    var displayName: String {
        switch self {
        case .line: return "Çizgi"
        case .area: return "Alan"
        case .candlestick: return "Mum"
        }
    }
    
    var icon: String {
        switch self {
        case .line: return "chart.line.uptrend.xyaxis"
        case .area: return "chart.area"
        case .candlestick: return "chart.bar"
        }
    }
}

enum TimeFrame: String, CaseIterable {
    case oneHour = "1h"
    case oneDay = "1d"
    case oneWeek = "1w"
    case oneMonth = "1m"
    case threeMonths = "3m"
    case oneYear = "1y"
    
    var displayName: String {
        switch self {
        case .oneHour: return "1 Saatlik"
        case .oneDay: return "1 Günlük"
        case .oneWeek: return "1 Haftalık"
        case .oneMonth: return "1 Aylık"
        case .threeMonths: return "3 Aylık"
        case .oneYear: return "1 Yıllık"
        }
    }
    
    var shortName: String {
        switch self {
        case .oneHour: return "1S"
        case .oneDay: return "1G"
        case .oneWeek: return "1H"
        case .oneMonth: return "1A"
        case .threeMonths: return "3A"
        case .oneYear: return "1Y"
        }
    }
    
    var dataPoints: Int {
        switch self {
        case .oneHour: return 60
        case .oneDay: return 24
        case .oneWeek: return 7
        case .oneMonth: return 30
        case .threeMonths: return 90
        case .oneYear: return 365
        }
    }
    
    var dateComponent: Calendar.Component {
        switch self {
        case .oneHour: return .minute
        case .oneDay: return .hour
        case .oneWeek: return .day
        case .oneMonth: return .day
        case .threeMonths: return .day
        case .oneYear: return .day
        }
    }
}

// MARK: - Note: StatCard and InfoRow are already defined in DashboardView
// Using existing components from the codebase

// MARK: - Preview
struct SymbolDetailView_Previews: PreviewProvider {
    static var previews: some View {
        SymbolDetailView(symbol: "AAPL")
            .preferredColorScheme(.dark)
    }
}
