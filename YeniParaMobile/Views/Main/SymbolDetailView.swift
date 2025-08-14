import SwiftUI
import Charts

struct SymbolDetailView: View {
    let symbol: String
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var navigationManager: NavigationManager
    @StateObject private var viewModel = SymbolDetailViewModel()
    @State private var selectedTimeframe: TimeFrame = .oneDay
    @State private var isFollowing: Bool = false
    @State private var showingShareSheet = false
    @State private var touchLocation: CGPoint? = nil
    @State private var isDragging = false
    @State private var selectedCandleIndex: Int? = nil
    
    private static let chartDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM HH:mm"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter
    }()
    
    private func formatChartDate(_ date: Date) -> String {
        Self.chartDateFormatter.string(from: date)
    }
    
    private static let xAxisFormatters: [TimeFrame: DateFormatter] = {
        var formatters: [TimeFrame: DateFormatter] = [:]
        let timeframes: [(TimeFrame, String)] = [
            (.oneDay, "HH:mm"),
            (.oneWeek, "d MMM"),
            (.oneMonth, "d MMM"),
            (.threeMonths, "MMM"),
            (.oneYear, "MMM yyyy")
        ]
        
        for (timeframe, format) in timeframes {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "tr_TR")
            formatter.dateFormat = format
            formatters[timeframe] = formatter
        }
        return formatters
    }()
    
    private func formatXAxisDate(_ date: Date) -> String {
        Self.xAxisFormatters[selectedTimeframe]?.string(from: date) ?? ""
    }
    
    private func getXAxisMarksCount() -> Int {
        switch selectedTimeframe {
        case .oneDay:
            return 4  // Reduced to prevent overlap
        case .oneWeek:
            return 4  // Reduced to prevent overlap
        case .oneMonth:
            return 4  // Show 4 marks for 1 month
        case .threeMonths:
            return 3  // Reduced for better spacing
        case .oneYear:
            return 3  // Reduced for better year display
        }
    }
    
    private func marketStatusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "open":
            return AppColors.success
        case "closed":
            return AppColors.error
        case "pre-market":
            return Color.orange
        case "after-hours":
            return AppColors.error  // Changed from purple to red
        default:
            return AppColors.textSecondary
        }
    }
    
    private func marketStatusText(_ status: String) -> String {
        switch status.lowercased() {
        case "open":
            return "AÇIK"
        case "closed":
            return "KAPALI"
        case "pre-market":
            return "ÖN SEANS"
        case "after-hours":
            return "KAPANIŞ SONRASI"
        default:
            return "KAPALI"
        }
    }
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Navigation Bar
                customNavigationBar
                
                if viewModel.isLoading {
                    LoadingView(message: "Hisse verileri yükleniyor...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error) {
                        Task {
                            await viewModel.loadData(symbol: symbol)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header with company info and price
                            headerSection
                            
                            // Chart section
                            chartSection
                            
                            // Sentiment section
                            StockSentimentView(symbol: symbol)
                                .padding(.horizontal, 20)
                            
                            // Comments section
                            StockCommentsView(symbol: symbol)
                                .frame(minHeight: 400)
                                .background(AppColors.cardBackground)
                                .cornerRadius(16)
                                .padding(.horizontal, 20)
                            
                            // Statistics section
                            statisticsSection
                            
                            // Company info section
                            companyInfoSection
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.loadData(symbol: symbol)
                await checkIfFollowing()
            }
        }
        .onDisappear {
            viewModel.stopPriceUpdates()
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [createShareText()])
        }
    }
    
    // MARK: - Custom Navigation Bar
    private var customNavigationBar: some View {
        HStack {
            Button(action: { 
                navigationManager.dismissStockDetail()
                dismiss() 
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Geri")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(AppColors.textPrimary)
            }
            
            Spacer()
            
            Text(symbol)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {
                    Task {
                        await toggleFollowStatus()
                    }
                }) {
                    Image(systemName: isFollowing ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(isFollowing ? AppColors.error : AppColors.textPrimary)
                }
                
                Button(action: { showingShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AppColors.background)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 20) {
            HStack(spacing: 16) {
                // Company Logo with oval shape
                StockLogoView(symbol: symbol, logoPath: viewModel.logoPath, size: 72, authToken: TokenManager.shared.getAccessToken())
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.cardBorder.opacity(0.3), lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.fundamental?.name ?? symbol)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Text(viewModel.fundamental?.exchange ?? "NASDAQ")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text("•")
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text(viewModel.fundamental?.currency ?? "USD")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Market status indicator
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(marketStatusColor(viewModel.marketInfo?.status ?? ""))
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .fill(marketStatusColor(viewModel.marketInfo?.status ?? ""))
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(viewModel.marketInfo?.isOpen == true ? 1.5 : 1)
                                    .opacity(viewModel.marketInfo?.isOpen == true ? 0 : 1)
                                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: viewModel.marketInfo?.isOpen)
                            )
                        
                        Text(marketStatusText(viewModel.marketInfo?.status ?? "closed"))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(viewModel.isMarketOpen ? Color.green : Color.red)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background((viewModel.isMarketOpen ? Color.green : Color.red).opacity(0.15))
                    .cornerRadius(12)
                }
            }
            
            // Price information
            VStack(spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatPrice(viewModel.currentPrice))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                            .animation(.easeInOut(duration: 0.2), value: viewModel.currentPrice)
                        
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: viewModel.isPositiveChange ? "arrow.up" : "arrow.down")
                                    .font(.system(size: 12, weight: .semibold))
                                Text(String(format: "%@%.2f", viewModel.isPositiveChange ? "+" : "", viewModel.priceChange))
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            
                            Text("(\(String(format: "%@%.2f%%", viewModel.isPositiveChange ? "+" : "", viewModel.priceChangePercent)))")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(viewModel.changeColor)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.priceChangePercent)
                    }
                    
                    Spacer()
                }
                
                // Market status info
                HStack(spacing: 8) {
                    Text(viewModel.isMarketOpen ? "Piyasa Açık" : "Piyasa Kapalı • NYSE: 16:30-23:00 TSI")
                        .font(.footnote)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Chart Section
    private var chartSection: some View {
        VStack(spacing: 0) {
            // Professional Chart Header
            HStack {
                Spacer()
                
                // Timeframe selector
                HStack(spacing: 4) {
                    ForEach([TimeFrame.oneDay, TimeFrame.oneWeek, TimeFrame.oneMonth, TimeFrame.threeMonths, TimeFrame.oneYear], id: \.rawValue) { timeframe in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTimeframe = timeframe
                                Task {
                                    await viewModel.loadChartData(symbol: symbol, timeframe: timeframe)
                                }
                            }
                        }) {
                            Text(timeframe.shortName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(selectedTimeframe == timeframe ? .black : AppColors.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedTimeframe == timeframe ? AppColors.primary : Color.clear)
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(4)
                .background(AppColors.cardBackground)
                .cornerRadius(10)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            // Chart Container
            ZStack {
                // Dark background
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 18/255, green: 19/255, blue: 26/255))
                
                if viewModel.candles.isEmpty {
                    // Loading State
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                            .scaleEffect(1.2)
                        Text("Grafik yükleniyor...")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(height: 400)
                } else {
                    // Professional Chart View
                    VStack(spacing: 0) {
                        // Price Chart
                        professionalChartView
                            .frame(height: 280)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        
                        // Separator
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 1)
                            .padding(.horizontal, 16)
                        
                        // Volume Chart
                        volumeChartView
                            .frame(height: 80)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    }
                    .frame(height: 400)
                    
                }
            }
            .frame(height: 400)
            .cornerRadius(16)
            .padding(.horizontal, 20)
        }
    }
    
    // Professional Chart View
    private var professionalChartView: some View {
        let minPrice = viewModel.candles.map { min($0.low, $0.open, $0.close) }.min() ?? 0
        let maxPrice = viewModel.candles.map { max($0.high, $0.open, $0.close) }.max() ?? 100
        let priceRange = maxPrice - minPrice
        let paddedMin = minPrice - (priceRange * 0.1)
        let paddedMax = maxPrice + (priceRange * 0.1)
        
        return GeometryReader { geometry in
            ZStack {
                // Chart
                Chart(viewModel.candles) { candle in
                    // Area gradient under the line
                    AreaMark(
                        x: .value("Time", candle.timestamp),
                        yStart: .value("Min", paddedMin),
                        yEnd: .value("Price", candle.close)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppColors.primary.opacity(0.2),
                                AppColors.primary.opacity(0.02)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    // Line Chart with shadow
                    LineMark(
                        x: .value("Time", candle.timestamp),
                        y: .value("Price", candle.close)
                    )
                    .foregroundStyle(AppColors.primary)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                    .shadow(color: AppColors.primary.opacity(0.5), radius: 3, x: 0, y: 2)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: getXAxisMarksCount())) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                            .foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(formatXAxisDate(date))
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color.white.opacity(0.6))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                        }
                    }
                }
                .chartYScale(domain: paddedMin...paddedMax)
                .chartYAxis {
                    AxisMarks(position: .trailing, values: .automatic(desiredCount: 6)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                            .foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel()
                            .font(.caption2)
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                }
                
                // Crosshair and interactive overlay
                if isDragging, let location = touchLocation {
                    // Vertical line
                    Path { path in
                        path.move(to: CGPoint(x: location.x, y: 0))
                        path.addLine(to: CGPoint(x: location.x, y: geometry.size.height))
                    }
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    
                    // Horizontal line
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: location.y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: location.y))
                    }
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    
                    // Circle at intersection
                    Circle()
                        .fill(AppColors.primary)
                        .frame(width: 8, height: 8)
                        .position(location)
                    
                    // Tooltip
                    if let index = selectedCandleIndex,
                       index >= 0 && index < viewModel.candles.count {
                        let candle = viewModel.candles[index]
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(formatChartDate(candle.timestamp))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Fiyat")
                                        .font(.system(size: 9))
                                        .foregroundColor(.white.opacity(0.6))
                                    Text(String(format: "$%.2f", candle.close))
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Hacim")
                                        .font(.system(size: 9))
                                        .foregroundColor(.white.opacity(0.6))
                                    Text(formatVolume(candle.volume))
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            // Change from first
                            if let firstCandle = viewModel.candles.first {
                                let change = candle.close - firstCandle.close
                                let changePercent = (change / firstCandle.close) * 100
                                
                                HStack(spacing: 3) {
                                    Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                                        .font(.system(size: 8, weight: .bold))
                                    Text(String(format: "%.2f%%", abs(changePercent)))
                                        .font(.system(size: 10, weight: .medium))
                                }
                                .foregroundColor(change >= 0 ? AppColors.primary : AppColors.error)
                            }
                        }
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.black.opacity(0.95))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                                )
                        )
                        .position(
                            x: min(max(60, location.x), geometry.size.width - 60),
                            y: max(35, location.y - 80)  // More space above finger
                        )
                    }
                }
                
                // Touch handler - SIMPLE VERSION WITHOUT Y-AXIS TRACKING
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let location = value.location
                                let xPercent = location.x / geometry.size.width
                                let index = Int(Double(viewModel.candles.count - 1) * xPercent)
                                
                                if index >= 0 && index < viewModel.candles.count {
                                    withAnimation(.none) {
                                        touchLocation = location  // Use finger position directly
                                        selectedCandleIndex = index
                                        isDragging = true
                                        viewModel.selectedCandle = viewModel.candles[index]
                                    }
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.easeOut(duration: 0.2)) {
                                    isDragging = false
                                    touchLocation = nil
                                    selectedCandleIndex = nil
                                    viewModel.selectedCandle = nil
                                }
                            }
                    )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }
    
    // Volume Chart View
    private var volumeChartView: some View {
        let maxVolume = viewModel.candles.map { $0.volume }.max() ?? 1
        let volumePadding = maxVolume * 0.2
        
        return Chart(viewModel.candles) { candle in
            BarMark(
                x: .value("Time", candle.timestamp),
                y: .value("Volume", candle.volume)
            )
            .foregroundStyle(
                candle.close >= candle.open ? 
                Color.green.opacity(0.8) : 
                Color.red.opacity(0.8)
            )
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: getXAxisMarksCount())) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                    .foregroundStyle(Color.white.opacity(0.1))
            }
        }
        .chartYScale(domain: 0...(maxVolume + volumePadding))
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 2)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                    .foregroundStyle(Color.white.opacity(0.1))
                AxisValueLabel {
                    if let volume = value.as(Double.self) {
                        Text(formatVolume(volume))
                            .font(.caption2)
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .padding(.bottom, 8)
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
            .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                // First row
                HStack(spacing: 16) {
                    DetailStatCard(
                        title: "Açılış",
                        value: formatPrice(viewModel.openPrice),
                        subtitle: "Önceki Kapanış",
                        subtitleValue: formatPrice(viewModel.previousClose)
                    )
                    
                    DetailStatCard(
                        title: "En Yüksek",
                        value: formatPrice(viewModel.high24h),
                        subtitle: "52H En Yüksek",
                        subtitleValue: formatPrice(viewModel.fundamental?.marketCapitalization != nil ? viewModel.high24h * 1.2 : 0)
                    )
                }
                
                // Second row
                HStack(spacing: 16) {
                    DetailStatCard(
                        title: "En Düşük",
                        value: formatPrice(viewModel.low24h),
                        subtitle: "52H En Düşük",
                        subtitleValue: formatPrice(viewModel.fundamental?.marketCapitalization != nil ? viewModel.low24h * 0.8 : 0)
                    )
                    
                    DetailStatCard(
                        title: "Ortalama Hacim",
                        value: formatVolume(viewModel.volume24h),
                        subtitle: "P/E Oranı",
                        subtitleValue: formatPERatio(viewModel.fundamental?.peRatio)
                    )
                }
                
                // Third row
                HStack(spacing: 16) {
                    DetailStatCard(
                        title: "Piyasa Değeri",
                        value: formatMarketCap(viewModel.fundamental?.marketCapitalization),
                        subtitle: "Hisse Başı Temettü",
                        subtitleValue: formatDividend(viewModel.fundamental?.dividendYield)
                    )
                    
                    DetailStatCard(
                        title: "F/K",
                        value: String(format: "%.2f", viewModel.fundamental?.peRatio ?? 0),
                        subtitle: "PD/DD",
                        subtitleValue: String(format: "%.2f", (viewModel.fundamental?.peRatio ?? 0) * 0.8)
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Company Info Section
    private var companyInfoSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Şirket Bilgileri")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 0) {
                DetailInfoRow(title: "Şirket Adı", value: viewModel.fundamental?.name ?? "N/A")
                Divider().background(AppColors.cardBorder)
                DetailInfoRow(title: "Sektör", value: viewModel.fundamental?.sector ?? "N/A")
                Divider().background(AppColors.cardBorder)
                DetailInfoRow(title: "Endüstri", value: viewModel.fundamental?.industry ?? "N/A")
                Divider().background(AppColors.cardBorder)
                DetailInfoRow(title: "Borsa", value: viewModel.fundamental?.exchange ?? "N/A")
                Divider().background(AppColors.cardBorder)
                DetailInfoRow(title: "Ülke", value: viewModel.fundamental?.country ?? "N/A")
                
                if let ipoDate = viewModel.fundamental?.ipoDate {
                    Divider().background(AppColors.cardBorder)
                    DetailInfoRow(title: "Halka Arz Tarihi", value: formatDate(ipoDate))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.cardBorder, lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
            
            // Temettü Detayları (mock data for now)
            VStack(spacing: 16) {
                HStack {
                    Text("Temettü Detayları")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Temettü Tarihi")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                            Text("15 Mayıs 2025")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Hisse Başı Temettü")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                            Text("$\(String(format: "%.2f", viewModel.fundamental?.dividendYield ?? 0))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                    
                    Button(action: {}) {
                        Text("Şirketin Temettü Geçmişini Göster")
                            .font(.subheadline)
                            .foregroundColor(AppColors.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.cardBorder, lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 20)
            
            // Analyst Recommendations
            if let targetPrice = viewModel.fundamental?.wallStreetTargetPrice,
               let analystRating = viewModel.fundamental?.analystRating {
                VStack(spacing: 16) {
                    HStack {
                        Text("Analist Tahminleri")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "info.circle")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Ortalama Fiyat Hedefi")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                        }
                        
                        HStack {
                            Text("$\(String(format: "%.2f", targetPrice))")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.textPrimary)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("En yüksek verilen fiyat hedefi $\(String(format: "%.2f", targetPrice * 1.2))")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                Text("En düşük verilen fiyat hedefi $\(String(format: "%.2f", targetPrice * 0.8))")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.cardBorder, lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func formatPrice(_ price: Double) -> String {
        if price == 0 { return "N/A" }
        return "$\(String(format: "%.2f", price))"
    }
    
    private func formatChangePercent(_ percent: Double) -> String {
        return String(format: "%.2f%%", abs(percent))
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1_000_000_000 {
            return String(format: "%.1fB", volume / 1_000_000_000)
        } else if volume >= 1_000_000 {
            return String(format: "%.1fM", volume / 1_000_000)
        } else if volume >= 1_000 {
            return String(format: "%.0fK", volume / 1_000)
        } else {
            return String(format: "%.0f", volume)
        }
    }
    
    private func formatMarketCap(_ marketCap: Double?) -> String {
        guard let marketCap = marketCap, marketCap > 0 else { return "N/A" }
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
    
    private func formatPERatio(_ peRatio: Double?) -> String {
        guard let peRatio = peRatio, peRatio > 0 else { return "N/A" }
        return String(format: "%.2f", peRatio)
    }
    
    private func formatDividend(_ dividendYield: Double?) -> String {
        guard let dividendYield = dividendYield, dividendYield > 0 else { return "0%" }
        return String(format: "%.2f%%", dividendYield)
    }
    
    private func formatDate(_ date: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let parsedDate = formatter.date(from: date) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.locale = Locale(identifier: "tr_TR")
            return displayFormatter.string(from: parsedDate)
        }
        return date
    }
    
    private func createShareText() -> String {
        let price = formatPrice(viewModel.currentPrice)
        let changeSymbol = viewModel.isPositiveChange ? "+" : "-"
        let change = String(format: "%.2f%%", abs(viewModel.priceChangePercent))
        return "\(symbol) - \(price) (\(changeSymbol)\(change)) - YeniPara'dan paylaşıldı"
    }
    
    private func toggleFollow() async {
        do {
            if isFollowing {
                _ = try await APIService.shared.unfollowStock(symbol: symbol)
                await MainActor.run {
                    isFollowing = false
                }
            } else {
                _ = try await APIService.shared.followStock(symbol: symbol, notifyOnNews: true, notifyOnComment: false)
                await MainActor.run {
                    isFollowing = true
                }
            }
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        } catch {
            print("Follow/unfollow error: \(error)")
        }
    }
    
    private func checkIfFollowing() async {
        do {
            let response = try await APIService.shared.getFollowedStocks()
            if response.success {
                await MainActor.run {
                    isFollowing = response.data.stocks.contains { $0.symbolCode == symbol }
                }
            }
        } catch {
            print("Check following error: \(error)")
        }
    }
    
    private func toggleFollowStatus() async {
        // Optimistically update UI first
        let wasFollowing = isFollowing
        
        await MainActor.run {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isFollowing = !wasFollowing
            }
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Then make API call
        do {
            if wasFollowing {
                // Unfollow
                _ = try await APIService.shared.unfollowStock(symbol: symbol)
            } else {
                // Follow with default notification settings
                _ = try await APIService.shared.followStock(symbol: symbol, notifyOnNews: false, notifyOnComment: false)
            }
        } catch {
            print("Toggle follow error: \(error)")
            // Revert on error
            await MainActor.run {
                withAnimation(.spring(response: 0.3)) {
                    isFollowing = wasFollowing
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct DetailStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let subtitleValue: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                Text(subtitleValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
}

struct DetailInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
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
enum TimeFrame: String, CaseIterable {
    case oneDay = "1D"
    case oneWeek = "1W"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case oneYear = "1Y"
    
    var shortName: String {
        switch self {
        case .oneDay: return "1G"
        case .oneWeek: return "1H"
        case .oneMonth: return "1A"
        case .threeMonths: return "3A"
        case .oneYear: return "1Y"
        }
    }
    
    var apiPeriod: String {
        return self.rawValue
    }
}

// MARK: - Chart Type

// MARK: - ViewModel
@MainActor
class SymbolDetailViewModel: ObservableObject {
    @Published var fundamental: DetailFundamentalData?
    @Published var candles: [DetailCandleData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCandle: DetailCandleData?
    @Published var selectedTimeframe: TimeFrame = .oneDay
    
    private var refreshTimer: Timer?
    
    // Price data
    @Published var currentPrice: Double = 0
    @Published var priceChange: Double = 0
    @Published var priceChangePercent: Double = 0
    @Published var volume24h: Double = 0
    @Published var high24h: Double = 0
    @Published var low24h: Double = 0
    @Published var openPrice: Double = 0
    @Published var previousClose: Double = 0
    
    // Stock info
    @Published var stockName: String = ""
    @Published var stockSector: String = ""
    @Published var stockIndustry: String = ""
    @Published var isMarketOpen: Bool = false
    @Published var marketInfo: MarketInfo?
    @Published var logoPath: String?
    
    var isPositiveChange: Bool { priceChange >= 0 }
    var changeColor: Color {
        isPositiveChange ? AppColors.primary : AppColors.error
    }
    
    func loadData(symbol: String) async {
        isLoading = true
        errorMessage = nil
        
        // Get market status from API
        await loadMarketStatus()
        
        // Load quote data and chart data in parallel
        async let quoteTask = loadQuoteData(symbol: symbol)
        async let chartTask = loadChartData(symbol: symbol, timeframe: .oneDay)
        
        let _ = await (quoteTask, chartTask)
        
        isLoading = false
        
        // Start auto refresh
        startPriceUpdates(symbol: symbol)
    }
    
    private func loadMarketStatus() async {
        do {
            let response = try await APIService.shared.getSP100Symbols()
            if let market = response.data.market {
                await MainActor.run {
                    self.marketInfo = market
                    self.isMarketOpen = market.isOpen
                }
            }
        } catch {
            // Fallback to local calculation if API fails
            checkMarketStatusLocally()
        }
    }
    
    private func checkMarketStatusLocally() {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.weekday, .hour, .minute], from: now)
        
        guard let weekday = components.weekday,
              let hour = components.hour,
              let minute = components.minute else { return }
        
        // Convert to Turkey time (UTC+3)
        let turkeyHour = (hour + 3) % 24
        let totalMinutes = turkeyHour * 60 + minute
        
        // NYSE: 9:30 AM - 4:00 PM ET
        // In Turkey time: 4:30 PM - 11:00 PM (16:30 - 23:00)
        let marketOpenTime = 16 * 60 + 30  // 16:30
        let marketCloseTime = 23 * 60       // 23:00
        
        // Check if weekend (Saturday = 7, Sunday = 1)
        if weekday == 1 || weekday == 7 {
            isMarketOpen = false
        } else if totalMinutes >= marketOpenTime && totalMinutes < marketCloseTime {
            isMarketOpen = true
        } else {
            isMarketOpen = false
        }
    }
    
    func loadQuoteData(symbol: String) async {
        do {
            // Get real-time quote data
            let quoteResponse = try await APIService.shared.getStockQuote(symbol: symbol)
            let quote = quoteResponse.data
            
            await MainActor.run {
                // Use latestPrice if available, otherwise fallback to price
                let latestPrice = quote.latestPrice ?? quote.price
                
                // Debug logging removed for production
                
                // Use API values directly
                self.currentPrice = latestPrice
                self.priceChange = quote.change
                self.priceChangePercent = quote.changePercent
                self.openPrice = quote.open
                self.high24h = quote.high
                self.low24h = quote.low
                self.previousClose = quote.prevClose
                self.volume24h = Double(quote.volume)
                self.logoPath = quote.logoPath
            }
            
            // Also refresh chart when price updates
            if selectedTimeframe == .oneDay {
                await loadChartData(symbol: symbol, timeframe: .oneDay)
            }
            
        } catch {
            print("Error loading quote data: \(error)")
            await MainActor.run {
                self.errorMessage = "Fiyat verileri yüklenemedi"
            }
        }
    }
    
    // Start real-time price updates
    func startPriceUpdates(symbol: String) {
        // Cancel any existing timer
        refreshTimer?.invalidate()
        
        // Refresh price every 60 seconds
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                await self.loadQuoteData(symbol: symbol)
                await self.loadMarketStatus()
            }
        }
    }
    
    func stopPriceUpdates() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    func loadChartData(symbol: String, timeframe: TimeFrame) async {
        do {
            let bars: [ChartBar]
            
            // Handle different timeframes
            switch timeframe {
            case .oneDay:
                // For 1 day, get minute bars
                let response = try await APIService.shared.getMinuteBars(symbol: symbol, days: 1)
                bars = response.data.bars.map { minuteBar in
                    ChartBar(
                        timestamp: minuteBar.timestamp,
                        date: nil,
                        open: minuteBar.open,
                        high: minuteBar.high,
                        low: minuteBar.low,
                        close: minuteBar.close,
                        volume: minuteBar.volume,
                        vwap: minuteBar.vwap,
                        tradeCount: minuteBar.tradeCount
                    )
                }
            case .oneWeek:
                // For 1 week, get minute bars and sample them
                let response = try await APIService.shared.getMinuteBars(symbol: symbol, days: 7)
                // Sample every 30th minute bar for 1 week view
                let samplingRate = max(1, response.data.bars.count / 200)
                bars = response.data.bars.enumerated().compactMap { index, minuteBar in
                    guard index % samplingRate == 0 else { return nil }
                    return ChartBar(
                        timestamp: minuteBar.timestamp,
                        date: nil,
                        open: minuteBar.open,
                        high: minuteBar.high,
                        low: minuteBar.low,
                        close: minuteBar.close,
                        volume: minuteBar.volume,
                        vwap: minuteBar.vwap,
                        tradeCount: minuteBar.tradeCount
                    )
                }
            case .oneMonth:
                // For 1 month, get daily bars
                let response = try await APIService.shared.getDailyBars(symbol: symbol, days: 30)
                bars = response.data.bars.map { dailyBar in
                    ChartBar(
                        timestamp: nil,
                        date: dailyBar.date,
                        open: dailyBar.open,
                        high: dailyBar.high,
                        low: dailyBar.low,
                        close: dailyBar.close,
                        volume: dailyBar.volume,
                        vwap: dailyBar.vwap,
                        tradeCount: dailyBar.tradeCount
                    )
                }
            case .threeMonths:
                // For 3 months, get daily bars  
                let response = try await APIService.shared.getDailyBars(symbol: symbol, days: 90)
                bars = response.data.bars.map { dailyBar in
                    ChartBar(
                        timestamp: nil,
                        date: dailyBar.date,
                        open: dailyBar.open,
                        high: dailyBar.high,
                        low: dailyBar.low,
                        close: dailyBar.close,
                        volume: dailyBar.volume,
                        vwap: dailyBar.vwap,
                        tradeCount: dailyBar.tradeCount
                    )
                }
            case .oneYear:
                // For 1 year, get daily bars
                let response = try await APIService.shared.getDailyBars(symbol: symbol, days: 365)
                bars = response.data.bars.map { dailyBar in
                    ChartBar(
                        timestamp: nil,
                        date: dailyBar.date,
                        open: dailyBar.open,
                        high: dailyBar.high,
                        low: dailyBar.low,
                        close: dailyBar.close,
                        volume: dailyBar.volume,
                        vwap: dailyBar.vwap,
                        tradeCount: dailyBar.tradeCount
                    )
                }
            }
            
            // Convert to DetailCandleData
            let candleData = bars.map { bar in
                DetailCandleData(
                    timestamp: parseTimestamp(bar.dateTime),
                    open: bar.open,
                    high: bar.high,
                    low: bar.low,
                    close: bar.close,
                    volume: Double(bar.volume)
                )
            }
            
            await MainActor.run {
                self.candles = candleData
                // Don't calculate price change from chart - use API values
            }
        } catch {
            print("Error loading chart data: \(error)")
            // Don't generate mock data, just leave empty
            await MainActor.run {
                self.candles = []
            }
        }
    }
    
    private func generateMockPriceData() {
        // Generate realistic price data
        let basePrice = Double.random(in: 100...800)
        let changePercent = Double.random(in: -8...8)
        let change = (basePrice * changePercent) / 100
        
        currentPrice = basePrice
        priceChange = change
        priceChangePercent = changePercent
        openPrice = basePrice - change + Double.random(in: -10...10)
        high24h = basePrice + Double.random(in: 5...25)
        low24h = basePrice - Double.random(in: 5...25)
        previousClose = basePrice - change
        volume24h = Double.random(in: 1_000_000...100_000_000)
    }
    
    private func generateMockChartData(timeframe: TimeFrame) async {
        let dataPoints = getDataPointsForTimeframe(timeframe)
        let basePrice = currentPrice > 0 ? currentPrice : Double.random(in: 100...800)
        
        var mockCandles: [DetailCandleData] = []
        let calendar = Calendar.current
        let now = Date()
        
        for i in 0..<dataPoints {
            let timeAgo: Date
            switch timeframe {
            case .oneDay:
                timeAgo = calendar.date(byAdding: .hour, value: -i, to: now) ?? now
            default:
                timeAgo = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            }
            
            let variation = Double.random(in: -0.05...0.05)
            let price = basePrice * (1 + variation)
            let open = price + Double.random(in: -2...2)
            let close = price + Double.random(in: -2...2)
            let high = max(open, close) + Double.random(in: 0...3)
            let low = min(open, close) - Double.random(in: 0...3)
            
            mockCandles.append(DetailCandleData(
                timestamp: timeAgo,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: Double.random(in: 1_000_000...10_000_000)
            ))
        }
        
        await MainActor.run {
            self.candles = mockCandles.reversed()
            if self.currentPrice == 0 {
                self.generateMockPriceData()
            }
            self.calculatePriceChangeFromChart()
        }
    }
    
    private func calculatePriceChangeFromChart() {
        guard let firstCandle = candles.first, let lastCandle = candles.last else { return }
        
        let startPrice = firstCandle.close
        let endPrice = lastCandle.close
        let change = endPrice - startPrice
        let changePercent = (change / startPrice) * 100
        
        currentPrice = endPrice
        priceChange = change
        priceChangePercent = changePercent
    }
    
    private func getDataPointsForTimeframe(_ timeframe: TimeFrame) -> Int {
        switch timeframe {
        case .oneDay:
            return 24
        case .oneWeek:
            return 7
        case .oneMonth:
            return 30
        case .threeMonths:
            return 90
        case .oneYear:
            return 365
        }
    }
    
    private func parseTimestamp(_ timestamp: String) -> Date {
        // Try ISO8601 format first
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
        
        if let date = formatter.date(from: timestamp) {
            return date
        }
        
        // Try custom format with timezone
        let customFormatter = DateFormatter()
        customFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        customFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = customFormatter.date(from: timestamp) {
            return date
        }
        
        // Fallback
        return Date()
    }
}

// MARK: - API Models
struct DetailFundamentalAPIResponse: Codable {
    let success: Bool
    let data: DetailFundamentalData
}

struct DetailFundamentalData: Codable {
    let symbolCode: String
    let code: String
    let name: String
    let exchange: String
    let currency: String
    let country: String?
    let isin: String?
    let ipoDate: String?
    let sector: String?
    let industry: String?
    let description: String?
    let address: String?
    let webUrl: String?
    let logoPath: String
    let logoUrl: String?
    let marketCapitalization: Double?
    let peRatio: Double?
    let earningsShare: Double?
    let dividendYield: Double?
    let wallStreetTargetPrice: Double?
    let analystRating: Int?
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case symbolCode = "symbol_code"
        case code, name, exchange, currency, country, isin, sector, industry, description, address
        case ipoDate = "ipo_date"
        case webUrl = "web_url"
        case logoPath = "logo_path"
        case logoUrl = "logo_url"
        case marketCapitalization = "market_capitalization"
        case peRatio = "pe_ratio"
        case earningsShare = "earnings_share"
        case dividendYield = "dividend_yield"
        case wallStreetTargetPrice = "wall_street_target_price"
        case analystRating = "analyst_rating"
        case updatedAt = "updated_at"
    }
}

struct DetailCandleAPIResponse: Codable {
    let cached: Bool
    let candle_count: Int
    let candles: [DetailCandleAPIModel]
}

struct DetailCandleAPIModel: Codable {
    let timestamp: String
    let symbol: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
}

struct DetailCandleData: Identifiable {
    let id = UUID()
    let timestamp: Date
    let open, high, low, close, volume: Double
}

// MARK: - Errors
enum SymbolDetailError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Geçersiz URL"
        case .invalidResponse:
            return "Geçersiz sunucu yanıtı"
        case .serverError(let code):
            return "Sunucu hatası: \(code)"
        case .decodingError:
            return "Veri işleme hatası"
        case .networkError:
            return "Ağ bağlantısı hatası"
        }
    }
}

// MARK: - Preview
struct SymbolDetailView_Previews: PreviewProvider {
    static var previews: some View {
        SymbolDetailView(symbol: "TSLA")
            .preferredColorScheme(.dark)
    }
}
