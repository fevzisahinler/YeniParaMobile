import SwiftUI
import Charts

// MARK: - Macro Detail View
struct MacroDetailView: View {
    let dataType: MacroDataType
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MacroDetailViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    LoadingView()
                } else if let error = viewModel.error {
                    ErrorView(
                        message: error,
                        onRetry: {
                            Task {
                                await viewModel.loadData(for: dataType)
                            }
                        }
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Summary Card
                            if let summary = viewModel.currentSummary {
                                MacroSummaryCard(
                                    dataType: dataType,
                                    summary: summary
                                )
                            }
                            
                            // Chart Section
                            if !viewModel.historicalData.isEmpty {
                                MacroChartSection(
                                    dataType: dataType,
                                    data: viewModel.historicalData
                                )
                            }
                            
                            // Historical Data List
                            MacroHistoricalList(
                                dataType: dataType,
                                data: viewModel.filteredHistoricalData
                            )
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle(dataType.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadData(for: dataType)
            }
        }
    }
}

// MARK: - Macro Detail View Model
@MainActor
class MacroDetailViewModel: ObservableObject {
    @Published var currentSummary: MacroDataSummary?
    @Published var historicalData: [MacroHistoricalDataPoint] = []
    @Published var isLoading = false
    @Published var error: String?
    
    var filteredHistoricalData: [MacroHistoricalDataPoint] {
        return historicalData
    }
    
    func loadData(for type: MacroDataType) async {
        isLoading = true
        error = nil
        
        do {
            // Load summary first
            let summary = try await MacroService.shared.getMacroSummary()
            
            // Extract current data based on type
            switch type {
            case .all:
                // For "all" view, we'll show a combined summary
                currentSummary = MacroDataSummary(
                    value: 0,
                    change: 0,
                    changePercent: 0,
                    date: Date(),
                    additionalInfo: "Tüm makroekonomik veriler"
                )
                
            case .gdp:
                currentSummary = MacroDataSummary(
                    value: summary.gdp.value,
                    change: summary.gdp.yoyChange,
                    changePercent: summary.gdp.yoyChange,
                    date: parseDate(summary.gdp.date),
                    additionalInfo: "QoQ: \(formatPercent(summary.gdp.qoqChange))"
                )
                let historical = try await MacroService.shared.getGDPHistorical(limit: 100)
                historicalData = historical.map { data in
                    MacroHistoricalDataPoint(
                        date: parseDate(data.date),
                        value: data.value,
                        change: data.yoyChange,
                        changePercent: data.yoyChange
                    )
                }
                
            case .cpi:
                currentSummary = MacroDataSummary(
                    value: summary.cpi.value,
                    change: summary.cpi.yoyInflation,
                    changePercent: summary.cpi.yoyInflation,
                    date: parseDate(summary.cpi.date),
                    additionalInfo: "MoM: \(formatPercent(summary.cpi.momChange))"
                )
                let historical = try await MacroService.shared.getCPIHistorical(limit: 100)
                historicalData = historical.map { data in
                    MacroHistoricalDataPoint(
                        date: parseDate(data.date),
                        value: data.value,
                        change: data.yoyInflation,
                        changePercent: data.yoyInflation
                    )
                }
                
            case .fedRate:
                currentSummary = MacroDataSummary(
                    value: summary.fedRate.rate,
                    change: summary.fedRate.change,
                    changePercent: (summary.fedRate.change / summary.fedRate.rate) * 100,
                    date: parseDate(summary.fedRate.date),
                    additionalInfo: "Faiz Oranı"
                )
                let historical = try await MacroService.shared.getFedRateHistorical(limit: 100)
                historicalData = historical.map { data in
                    MacroHistoricalDataPoint(
                        date: parseDate(data.date),
                        value: data.rate,
                        change: data.change,
                        changePercent: data.rate > 0 ? (data.change / data.rate) * 100 : 0
                    )
                }
                
            case .unemployment:
                currentSummary = MacroDataSummary(
                    value: summary.unemployment.rate,
                    change: summary.unemployment.change,
                    changePercent: (summary.unemployment.change / summary.unemployment.rate) * 100,
                    date: parseDate(summary.unemployment.date),
                    additionalInfo: "İşsizlik Oranı"
                )
                let historical = try await MacroService.shared.getUnemploymentHistorical(limit: 100)
                historicalData = historical.map { data in
                    MacroHistoricalDataPoint(
                        date: parseDate(data.date),
                        value: data.rate,
                        change: data.change,
                        changePercent: data.rate > 0 ? (data.change / data.rate) * 100 : 0
                    )
                }
                
            case .oil:
                currentSummary = MacroDataSummary(
                    value: summary.oilPrice.price,
                    change: summary.oilPrice.change,
                    changePercent: summary.oilPrice.percentChange,
                    date: parseDate(summary.oilPrice.date),
                    additionalInfo: "Varil Başına"
                )
                let historical = try await MacroService.shared.getOilPriceHistorical(limit: 100)
                historicalData = historical.map { data in
                    MacroHistoricalDataPoint(
                        date: parseDate(data.date),
                        value: data.price,
                        change: data.change,
                        changePercent: data.percentChange
                    )
                }
                
            case .retailSales:
                currentSummary = MacroDataSummary(
                    value: summary.retailSales.value,
                    change: summary.retailSales.yoyChange,
                    changePercent: summary.retailSales.yoyChange,
                    date: parseDate(summary.retailSales.date),
                    additionalInfo: "MoM: \(formatPercent(summary.retailSales.momChange))"
                )
                let historical = try await MacroService.shared.getRetailSalesHistorical(limit: 100)
                historicalData = historical.map { data in
                    MacroHistoricalDataPoint(
                        date: parseDate(data.date),
                        value: data.value,
                        change: data.yoyChange,
                        changePercent: data.yoyChange
                    )
                }
            }
            
            // Sort historical data by date
            historicalData.sort { $0.date > $1.date }
            
        } catch {
            self.error = "Veriler yüklenemedi: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func parseDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter.date(from: dateString) ?? Date()
    }
    
    private func formatPercent(_ value: Double) -> String {
        return String(format: "%.2f%%", abs(value))
    }
}

// MARK: - Data Models
struct MacroDataSummary {
    let value: Double
    let change: Double
    let changePercent: Double
    let date: Date
    let additionalInfo: String
}

struct MacroHistoricalDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let change: Double
    let changePercent: Double
}


// MARK: - Summary Card
struct MacroSummaryCard: View {
    let dataType: MacroDataType
    let summary: MacroDataSummary
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: dataType.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(getColor(for: dataType))
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(getColor(for: dataType).opacity(0.15))
                    )
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatValue(summary.value, for: dataType))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: summary.change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 12, weight: .bold))
                        
                        Text(formatChange(summary.change, for: dataType))
                            .font(.system(size: 14, weight: .semibold))
                        
                        Text("(\(String(format: "%.2f%%", abs(summary.changePercent))))")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(getChangeColor(summary.change, for: dataType))
                }
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Son Güncelleme")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text(formatDate(summary.date))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Spacer()
                
                if !summary.additionalInfo.isEmpty {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Ek Bilgi")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text(summary.additionalInfo)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private func getColor(for type: MacroDataType) -> Color {
        switch type {
        case .all: return .gray
        case .gdp: return .blue
        case .cpi: return .orange
        case .fedRate: return .purple
        case .unemployment: return .green
        case .oil: return .brown
        case .retailSales: return .pink
        }
    }
    
    private func getChangeColor(_ change: Double, for type: MacroDataType) -> Color {
        switch type {
        case .cpi, .unemployment, .fedRate:
            // For these, lower is generally better
            return change <= 0 ? AppColors.success : AppColors.error
        default:
            // For others, higher is generally better
            return change >= 0 ? AppColors.success : AppColors.error
        }
    }
    
    private func formatValue(_ value: Double, for type: MacroDataType) -> String {
        switch type {
        case .gdp:
            let trillion = value / 1000
            return String(format: "$%.1fT", trillion)
        case .cpi:
            return String(format: "%.1f", value)
        case .fedRate, .unemployment:
            return String(format: "%.2f%%", value)
        case .oil:
            return String(format: "$%.2f", value)
        case .retailSales:
            let billion = value / 1000
            return String(format: "$%.0fB", billion)
        default:
            return String(format: "%.2f", value)
        }
    }
    
    private func formatChange(_ change: Double, for type: MacroDataType) -> String {
        switch type {
        case .fedRate, .unemployment:
            return String(format: "%+.2f", change)
        default:
            return String(format: "%+.2f", change)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}

// MARK: - Chart Section
struct MacroChartSection: View {
    let dataType: MacroDataType
    let data: [MacroHistoricalDataPoint]
    
    var body: some View {
        VStack(spacing: 16) {
            // Chart Title
            HStack {
                Text("Geçmiş Veriler Grafiği")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text("Tüm Zamanlar")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(AppColors.cardBackground)
                            .overlay(
                                Capsule()
                                    .stroke(AppColors.cardBorder, lineWidth: 1)
                            )
                    )
            }
            .padding(.horizontal, 20)
            
            // Chart
            if #available(iOS 16.0, *) {
                Chart(data) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(AppColors.primary)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.primary.opacity(0.3), AppColors.primary.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 200)
                .padding(.horizontal, 20)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                            .foregroundStyle(AppColors.cardBorder.opacity(0.3))
                        AxisValueLabel()
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                            .foregroundStyle(AppColors.cardBorder.opacity(0.3))
                        AxisValueLabel()
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            } else {
                // Fallback for iOS 15
                Text("Grafik iOS 16+ gerektirir")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.cardBackground)
                    )
                    .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Historical List
struct MacroHistoricalList: View {
    let dataType: MacroDataType
    let data: [MacroHistoricalDataPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Geçmiş Veriler")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 20)
            
            LazyVStack(spacing: 8) {
                ForEach(data.prefix(20)) { point in
                    MacroHistoricalRow(
                        dataType: dataType,
                        dataPoint: point
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Historical Row
struct MacroHistoricalRow: View {
    let dataType: MacroDataType
    let dataPoint: MacroHistoricalDataPoint
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(dataPoint.date))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(formatTime(dataPoint.date))
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatValue(dataPoint.value, for: dataType))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: 4) {
                    Image(systemName: dataPoint.change >= 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 10, weight: .bold))
                    
                    Text(String(format: "%.2f%%", abs(dataPoint.changePercent)))
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(getChangeColor(dataPoint.change, for: dataType))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.day], from: date, to: now)
        
        if let days = components.day {
            if days == 0 {
                return "Bugün"
            } else if days == 1 {
                return "Dün"
            } else if days < 7 {
                return "\(days) gün önce"
            } else if days < 30 {
                return "\(days / 7) hafta önce"
            } else if days < 365 {
                return "\(days / 30) ay önce"
            } else {
                return "\(days / 365) yıl önce"
            }
        }
        
        return ""
    }
    
    private func formatValue(_ value: Double, for type: MacroDataType) -> String {
        switch type {
        case .gdp:
            let trillion = value / 1000
            return String(format: "$%.1fT", trillion)
        case .cpi:
            return String(format: "%.1f", value)
        case .fedRate, .unemployment:
            return String(format: "%.2f%%", value)
        case .oil:
            return String(format: "$%.2f", value)
        case .retailSales:
            let billion = value / 1000
            return String(format: "$%.0fB", billion)
        default:
            return String(format: "%.2f", value)
        }
    }
    
    private func getChangeColor(_ change: Double, for type: MacroDataType) -> Color {
        switch type {
        case .cpi, .unemployment, .fedRate:
            return change <= 0 ? AppColors.success : AppColors.error
        default:
            return change >= 0 ? AppColors.success : AppColors.error
        }
    }
}