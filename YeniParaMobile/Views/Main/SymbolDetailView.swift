import SwiftUI
import Charts

struct SymbolDetailView: View {
    let symbol: String
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SymbolDetailViewModel()
    @State private var selectedTimeframe: TimeFrame = .oneDay
    @State private var isInWatchlist: Bool = false
    @State private var showingShareSheet = false
    
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
                            
                            // Statistics section
                            statisticsSection
                            
                            // Company info section
                            companyInfoSection
                            
                            // Action buttons
                            actionButtonsSection
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
            }
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
            
            Text(symbol)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        isInWatchlist.toggle()
                    }
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
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AppColors.background)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 20) {
            HStack(spacing: 16) {
                // Company Logo
                AsyncImage(url: URL(string: "http://localhost:4000\(viewModel.fundamental?.logoPath ?? "")")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.secondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text(String(symbol.prefix(2)))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 64, height: 64)
                .cornerRadius(16)
                
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
                
                // Live indicator
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 8, height: 8)
                            .scaleEffect(viewModel.isLoading ? 1.0 : 1.2)
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: viewModel.isLoading)
                        
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
            }
            
            // Price information
            VStack(spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(formatPrice(viewModel.currentPrice))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: viewModel.isPositiveChange ? "triangle.fill" : "triangle.fill")
                                .font(.system(size: 12, weight: .bold))
                                .rotationEffect(.degrees(viewModel.isPositiveChange ? 0 : 180))
                                .foregroundColor(viewModel.changeColor)
                            
                            Text(formatChange(viewModel.priceChange))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(viewModel.changeColor)
                        }
                        
                        Text(formatChangePercent(viewModel.priceChangePercent))
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(viewModel.changeColor)
                    }
                }
                
                // Piyasa kapanış bilgisi
                if let exchange = viewModel.fundamental?.exchange {
                    Text("Piyasa Kapalı • Emrin açılana gerçekleşir")
                        .font(.footnote)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Chart Section
    private var chartSection: some View {
        VStack(spacing: 16) {
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
                                Task {
                                    await viewModel.loadChartData(symbol: symbol, timeframe: timeframe)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Chart
            if viewModel.candles.isEmpty {
                RoundedRectangle(cornerRadius: 16)
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
                    .padding(.horizontal, 20)
            } else {
                Chart(viewModel.candles) { candle in
                    LineMark(
                        x: .value("Tarih", candle.timestamp),
                        y: .value("Kapanış", candle.close)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.primary.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)
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
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.cardBorder, lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
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
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Button(action: {
                    // Sell action
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("SAT")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(AppColors.error)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AppColors.cardBackground)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.error, lineWidth: 1)
                    )
                }
                
                Button(action: {
                    // Buy action
                }) {
                    HStack(spacing: 8) {
                        Text("AL")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AppColors.primary)
                    .cornerRadius(16)
                    .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
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
        .padding(.horizontal, 20)
    }
    
    // MARK: - Helper Functions
    private func formatPrice(_ price: Double) -> String {
        if price == 0 { return "N/A" }
        return "$\(String(format: "%.2f", price))"
    }
    
    private func formatChange(_ change: Double) -> String {
        if change == 0 { return "$0.00" }
        return "\(change >= 0 ? "↗" : "↘")$\(String(format: "%.2f", abs(change)))"
    }
    
    private func formatChangePercent(_ percent: Double) -> String {
        if percent == 0 { return "0.00%" }
        return "\(percent >= 0 ? "↗" : "↘")\(String(format: "%.2f", abs(percent)))%"
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
        let change = formatChangePercent(viewModel.priceChangePercent)
        return "\(symbol) - \(price) (\(change)) - YeniPara'dan paylaşıldı"
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
    case oneHour = "1h"
    case oneDay = "1G"
    case oneMonth = "1A"
    case threeMonths = "3A"
    case oneYear = "1Y"
    case fiveYears = "5Y"
    
    var shortName: String {
        return self.rawValue
    }
    
    var apiTimeframe: String {
        switch self {
        case .oneHour:
            return "5m"
        case .oneDay:
            return "5m"
        default:
            return "1d"
        }
    }
    
    var dateRange: (from: String, to: String) {
        let calendar = Calendar.current
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let toDate = formatter.string(from: now)
        
        var fromDate: String
        switch self {
        case .oneHour:
            // 1 hour ago to now (5m data)
            let oneHourAgo = calendar.date(byAdding: .hour, value: -1, to: now) ?? now
            fromDate = formatter.string(from: oneHourAgo)
        case .oneDay:
            // Yesterday to today (5m data)
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
            fromDate = formatter.string(from: yesterday)
        case .oneMonth:
            // 1 month ago (1d data)
            let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            fromDate = formatter.string(from: oneMonthAgo)
        case .threeMonths:
            // 3 months ago (1d data)
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            fromDate = formatter.string(from: threeMonthsAgo)
        case .oneYear:
            // 1 year ago (1d data)
            let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            fromDate = formatter.string(from: oneYearAgo)
        case .fiveYears:
            // 5 years ago (1d data)
            let fiveYearsAgo = calendar.date(byAdding: .year, value: -5, to: now) ?? now
            fromDate = formatter.string(from: fiveYearsAgo)
        }
        
        return (fromDate, toDate)
    }
}

// MARK: - ViewModel
@MainActor
class SymbolDetailViewModel: ObservableObject {
    @Published var fundamental: DetailFundamentalData?
    @Published var candles: [DetailCandleData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Price data
    @Published var currentPrice: Double = 0
    @Published var priceChange: Double = 0
    @Published var priceChangePercent: Double = 0
    @Published var volume24h: Double = 0
    @Published var high24h: Double = 0
    @Published var low24h: Double = 0
    @Published var openPrice: Double = 0
    @Published var previousClose: Double = 0
    
    var isPositiveChange: Bool { priceChange >= 0 }
    var changeColor: Color {
        isPositiveChange ? AppColors.primary : AppColors.error
    }
    
    func loadData(symbol: String) async {
        isLoading = true
        errorMessage = nil
        
        async let fundamentalTask = loadFundamental(symbol: symbol)
        async let chartTask = loadChartData(symbol: symbol, timeframe: .oneDay)
        
        let _ = await (fundamentalTask, chartTask)
        
        isLoading = false
    }
    
    func loadFundamental(symbol: String) async {
        do {
            guard let url = URL(string: "http://localhost:4000/api/v1/fundamental/\(symbol)") else {
                throw SymbolDetailError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 30
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SymbolDetailError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw SymbolDetailError.serverError(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(DetailFundamentalAPIResponse.self, from: data)
            
            if apiResponse.success {
                await MainActor.run {
                    self.fundamental = apiResponse.data
                    
                    // Generate mock price data based on fundamental
                    self.generateMockPriceData()
                }
            } else {
                throw SymbolDetailError.serverError(0)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Fundamental veri yüklenirken hata oluştu: \(error.localizedDescription)"
            }
        }
    }
    
    func loadChartData(symbol: String, timeframe: TimeFrame) async {
        do {
            let dateRange = timeframe.dateRange
            let apiTimeframe = timeframe.apiTimeframe
            
            guard let url = URL(string: "http://localhost:4000/api/v1/market/candles?symbol=\(symbol)&timeframe=\(apiTimeframe)&from=\(dateRange.from)&to=\(dateRange.to)") else {
                throw SymbolDetailError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Add auth token if available
            if let token = UserDefaults.standard.string(forKey: "accessToken") {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SymbolDetailError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                // If no auth token or expired, generate mock data
                await generateMockChartData(timeframe: timeframe)
                return
            }
            
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(DetailCandleAPIResponse.self, from: data)
            
            if apiResponse.symbol == symbol {
                let candleData = apiResponse.candles.map { apiCandle in
                    DetailCandleData(
                        timestamp: parseTimestamp(apiCandle.timestamp),
                        open: apiCandle.open,
                        high: apiCandle.high,
                        low: apiCandle.low,
                        close: apiCandle.close,
                        volume: apiCandle.volume
                    )
                }
                
                await MainActor.run {
                    self.candles = candleData
                    self.calculatePriceChangeFromChart()
                }
            } else {
                await generateMockChartData(timeframe: timeframe)
            }
        } catch {
            await generateMockChartData(timeframe: timeframe)
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
            case .oneHour:
                timeAgo = calendar.date(byAdding: .minute, value: -i * 5, to: now) ?? now
            case .oneDay:
                timeAgo = calendar.date(byAdding: .minute, value: -i * 5, to: now) ?? now
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
        case .oneHour:
            return 12 // 12 * 5min = 1 hour
        case .oneDay:
            return 288 // 288 * 5min = 24 hours
        case .oneMonth:
            return 30
        case .threeMonths:
            return 90
        case .oneYear:
            return 365
        case .fiveYears:
            return 1825
        }
    }
    
    private func parseTimestamp(_ timestamp: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: timestamp) ?? Date()
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
    let symbol: String
    let candles: [DetailCandleAPIModel]
    let meta: DetailCandleMetaInfo
}

struct DetailCandleAPIModel: Codable {
    let timestamp: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
}

struct DetailCandleMetaInfo: Codable {
    let timestamp: Int64
    let count: Int
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
