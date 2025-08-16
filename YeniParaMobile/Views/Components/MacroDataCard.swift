import SwiftUI

// MARK: - Macro Indicator Info Sheet
struct MacroIndicatorInfoSheet: View {
    let info: MacroIndicatorInfo
    let color: Color
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: getIcon(for: info.indicator))
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(color)
                                .frame(width: 48, height: 48)
                                .background(
                                    Circle()
                                        .fill(color.opacity(0.15))
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(info.name)
                                    .font(.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Text(info.description)
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.cardBackground)
                    )
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Artış Durumunda")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.success)
                                Text(info.increaseEffect)
                                    .font(.system(size: 13))
                                    .foregroundColor(AppColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        } icon: {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(AppColors.success)
                        }
                        
                        Divider()
                        
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Azalış Durumunda")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.error)
                                Text(info.decreaseEffect)
                                    .font(.system(size: 13))
                                    .foregroundColor(AppColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        } icon: {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(AppColors.error)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.cardBackground)
                    )
                }
                .padding()
            }
            .background(AppColors.background)
            .navigationTitle("Gösterge Bilgisi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }
    
    private func getIcon(for indicator: String) -> String {
        switch indicator {
        case "gdp": return "chart.line.uptrend.xyaxis"
        case "cpi": return "cart.fill"
        case "fed_rate": return "percent"
        case "unemployment": return "person.3.fill"
        case "oil_price": return "drop.fill"
        case "retail_sales": return "bag.fill"
        default: return "chart.bar.doc.horizontal"
        }
    }
}

// MARK: - Compact Macro Card (New Design)
struct CompactMacroCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    let icon: String
    let color: Color
    let indicatorInfo: MacroIndicatorInfo?
    let previousChange: String?
    
    @State private var showInfo = false
    
    var displayChange: String {
        if change == "0.00" || change == "+0.00" || change == "0.00%" {
            if let prev = previousChange, prev != "0.00" && prev != "+0.00" && prev != "0.00%" {
                return prev
            }
        }
        return change
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: 4) {
                Image(systemName: displayChange == "0.00" || displayChange == "+0.00" || displayChange == "0.00%" ? "minus" : (isPositive ? "arrow.up.right" : "arrow.down.right"))
                    .font(.system(size: 10, weight: .bold))
                
                Text(displayChange)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(displayChange == "0.00" || displayChange == "+0.00" || displayChange == "0.00%" ? AppColors.textSecondary : (isPositive ? AppColors.success : AppColors.error))
            
            if indicatorInfo != nil {
                Button(action: { showInfo.toggle() }) {
                    HStack(spacing: 2) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 10))
                        Text("Bilgi")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
        .padding(AppConstants.cardPadding)
        .frame(width: 120)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )
        )
        .sheet(isPresented: $showInfo) {
            if let info = indicatorInfo {
                MacroIndicatorInfoSheet(info: info, color: color)
            }
        }
    }
}

// MARK: - Macro Data Card (Original - Keep for detail pages)
struct MacroDataCard: View {
    let title: String
    let icon: String
    let value: String
    let change: String
    let changePercent: String?
    let isPositive: Bool
    let date: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(color.opacity(0.15))
                        )
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textTertiary)
                }
                
                // Title
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                
                // Value
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                // Change
                HStack(spacing: 4) {
                    Image(systemName: change == "0.00" || change == "+0.00" ? "minus" : (isPositive ? "arrow.up.right" : "arrow.down.right"))
                        .font(.system(size: 10, weight: .bold))
                    
                    Text(change)
                        .font(.system(size: 12, weight: .semibold))
                    
                    if let changePercent = changePercent {
                        Text("(\(changePercent))")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                .foregroundColor(change == "0.00" || change == "+0.00" ? AppColors.textSecondary : (isPositive ? AppColors.success : AppColors.error))
                
                // Date
                Text(date)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.cardBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Macro Summary Section (Compact)
struct MacroSummarySection: View {
    let macroData: MacroSummary
    let onNavigateToDetail: (MacroDataType) -> Void
    @State private var indicatorInfos: [String: MacroIndicatorInfo] = [:]
    @State private var previousChanges: [String: String] = [:]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            Text("Makroekonomik Veriler")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, AppConstants.screenPadding)
            
            // Horizontal Scroll Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // GDP Card
                    CompactMacroCard(
                        title: "GDP",
                        value: formatGDPValue(macroData.gdp.value),
                        change: formatPercent(macroData.gdp.yoyChange),
                        isPositive: macroData.gdp.yoyChange >= 0,
                        icon: "chart.line.uptrend.xyaxis",
                        color: AppColors.primary,
                        indicatorInfo: indicatorInfos["gdp"],
                        previousChange: previousChanges["gdp"]
                    )
                    .onTapGesture { onNavigateToDetail(.gdp) }
                    
                    // CPI Card
                    CompactMacroCard(
                        title: "Enflasyon",
                        value: formatCPIValue(macroData.cpi.value),
                        change: formatPercent(macroData.cpi.yoyInflation),
                        isPositive: macroData.cpi.yoyInflation <= 2.5,
                        icon: "cart.fill",
                        color: Color.orange,
                        indicatorInfo: indicatorInfos["cpi"],
                        previousChange: previousChanges["cpi"]
                    )
                    .onTapGesture { onNavigateToDetail(.cpi) }
                    
                    // Fed Rate Card
                    CompactMacroCard(
                        title: "Fed Faiz",
                        value: formatRateValue(macroData.fedRate.rate),
                        change: formatChange(macroData.fedRate.change),
                        isPositive: macroData.fedRate.change <= 0,
                        icon: "percent",
                        color: Color.purple,
                        indicatorInfo: indicatorInfos["fed_rate"],
                        previousChange: previousChanges["fed_rate"]
                    )
                    .onTapGesture { onNavigateToDetail(.fedRate) }
                    
                    // Unemployment Card
                    CompactMacroCard(
                        title: "İşsizlik",
                        value: formatRateValue(macroData.unemployment.rate),
                        change: formatChange(macroData.unemployment.change),
                        isPositive: macroData.unemployment.change <= 0,
                        icon: "person.3.fill",
                        color: Color.green,
                        indicatorInfo: indicatorInfos["unemployment"],
                        previousChange: previousChanges["unemployment"]
                    )
                    .onTapGesture { onNavigateToDetail(.unemployment) }
                    
                    // Oil Price Card
                    CompactMacroCard(
                        title: "Petrol",
                        value: "$\(String(format: "%.2f", macroData.oilPrice.price))",
                        change: formatPercent(macroData.oilPrice.percentChange),
                        isPositive: macroData.oilPrice.change >= 0,
                        icon: "drop.fill",
                        color: Color.brown,
                        indicatorInfo: indicatorInfos["oil_price"],
                        previousChange: previousChanges["oil_price"]
                    )
                    .onTapGesture { onNavigateToDetail(.oil) }
                    
                    // Retail Sales Card
                    CompactMacroCard(
                        title: "Perakende",
                        value: formatRetailValueCompact(macroData.retailSales.value),
                        change: formatPercent(macroData.retailSales.yoyChange),
                        isPositive: macroData.retailSales.yoyChange >= 0,
                        icon: "bag.fill",
                        color: Color.pink,
                        indicatorInfo: indicatorInfos["retail_sales"],
                        previousChange: previousChanges["retail_sales"]
                    )
                    .onTapGesture { onNavigateToDetail(.retailSales) }
                }
                .padding(.horizontal, AppConstants.screenPadding)
            }
        }
        .task {
            await loadIndicatorInfo()
            await loadPreviousChanges()
        }
    }
    
    private func loadIndicatorInfo() async {
        do {
            let infos = try await MacroService.shared.getIndicatorInfo()
            var infoDict: [String: MacroIndicatorInfo] = [:]
            for info in infos {
                infoDict[info.indicator] = info
            }
            await MainActor.run {
                self.indicatorInfos = infoDict
            }
        } catch {
            print("Failed to load indicator info: \(error)")
        }
    }
    
    private func loadPreviousChanges() async {
        do {
            async let gdpHistory = MacroService.shared.getGDPHistorical(limit: 2)
            async let cpiHistory = MacroService.shared.getCPIHistorical(limit: 2)
            async let fedHistory = MacroService.shared.getFedRateHistorical(limit: 2)
            async let unemploymentHistory = MacroService.shared.getUnemploymentHistorical(limit: 2)
            async let oilHistory = MacroService.shared.getOilPriceHistorical(limit: 2)
            async let retailHistory = MacroService.shared.getRetailSalesHistorical(limit: 2)
            
            let (gdp, cpi, fed, unemployment, oil, retail) = try await (gdpHistory, cpiHistory, fedHistory, unemploymentHistory, oilHistory, retailHistory)
            
            await MainActor.run {
                // GDP - Calculate from actual values
                if gdp.count > 1 && abs(macroData.gdp.yoyChange) < 0.01 {
                    let currentValue = macroData.gdp.value
                    let previousValue = gdp[1].value
                    let actualChangePercent = previousValue > 0 ? ((currentValue - previousValue) / previousValue) * 100 : 0
                    previousChanges["gdp"] = formatPercent(actualChangePercent)
                }
                
                // CPI - Calculate from actual values
                if cpi.count > 1 && abs(macroData.cpi.yoyInflation) < 0.01 {
                    let currentValue = macroData.cpi.value
                    let previousValue = cpi[1].value
                    let actualChangePercent = previousValue > 0 ? ((currentValue - previousValue) / previousValue) * 100 : 0
                    previousChanges["cpi"] = formatPercent(actualChangePercent)
                }
                
                // Fed Rate - Calculate from actual values
                if fed.count > 1 && abs(macroData.fedRate.change) < 0.01 {
                    let currentValue = macroData.fedRate.rate
                    let previousValue = fed[1].rate
                    let actualChange = currentValue - previousValue
                    previousChanges["fed_rate"] = formatChange(actualChange)
                }
                
                // Unemployment - Calculate from actual values
                if unemployment.count > 1 && abs(macroData.unemployment.change) < 0.01 {
                    let currentValue = macroData.unemployment.rate
                    let previousValue = unemployment[1].rate
                    let actualChange = currentValue - previousValue
                    previousChanges["unemployment"] = formatChange(actualChange)
                }
                
                // Oil - Calculate from actual values
                if oil.count > 1 && abs(macroData.oilPrice.percentChange) < 0.01 {
                    let currentValue = macroData.oilPrice.price
                    let previousValue = oil[1].price
                    let actualChangePercent = previousValue > 0 ? ((currentValue - previousValue) / previousValue) * 100 : 0
                    previousChanges["oil_price"] = formatPercent(actualChangePercent)
                }
                
                // Retail Sales - Calculate from actual values
                if retail.count > 1 && abs(macroData.retailSales.yoyChange) < 0.01 {
                    let currentValue = macroData.retailSales.value
                    let previousValue = retail[1].value
                    let actualChangePercent = previousValue > 0 ? ((currentValue - previousValue) / previousValue) * 100 : 0
                    previousChanges["retail_sales"] = formatPercent(actualChangePercent)
                }
            }
        } catch {
            print("Failed to load previous changes: \(error)")
        }
    }
}

// MARK: - Macro Data Type
enum MacroDataType {
    case all
    case gdp
    case cpi
    case fedRate
    case unemployment
    case oil
    case retailSales
    
    var title: String {
        switch self {
        case .all: return "Tüm Veriler"
        case .gdp: return "GDP (GSYİH)"
        case .cpi: return "CPI (Enflasyon)"
        case .fedRate: return "Fed Faiz Oranı"
        case .unemployment: return "İşsizlik Oranı"
        case .oil: return "Petrol Fiyatı"
        case .retailSales: return "Perakende Satışlar"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "chart.bar.doc.horizontal"
        case .gdp: return "chart.line.uptrend.xyaxis"
        case .cpi: return "cart.fill"
        case .fedRate: return "percent"
        case .unemployment: return "person.3.fill"
        case .oil: return "drop.fill"
        case .retailSales: return "bag.fill"
        }
    }
}

// MARK: - Formatting Helpers
private func formatGDPValue(_ value: Double) -> String {
    let trillion = value / 1000
    return String(format: "$%.1fT", trillion)
}

private func formatCPIValue(_ value: Double) -> String {
    return String(format: "%.1f", value)
}

private func formatRateValue(_ value: Double) -> String {
    return String(format: "%.2f%%", value)
}

private func formatPriceValue(_ value: Double) -> String {
    return String(format: "$%.2f", value)
}

private func formatRetailValue(_ value: Double) -> String {
    let billion = value / 1000
    return String(format: "$%.0fB", billion)
}

private func formatRetailValueCompact(_ value: Double) -> String {
    let billion = value / 1000
    return String(format: "$%.0fB", billion)
}

private func formatChange(_ value: Double) -> String {
    if value >= 0 {
        return String(format: "+%.2f", abs(value))
    } else {
        return String(format: "-%.2f", abs(value))
    }
}

private func formatPercent(_ value: Double) -> String {
    return String(format: "%.2f%%", abs(value))
}

private func formatDate(_ dateString: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    
    if let date = formatter.date(from: dateString) {
        formatter.dateFormat = "dd MMM yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
    
    return dateString
}

private func formatLastUpdated(_ dateString: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZ"
    
    if let date = formatter.date(from: dateString) {
        formatter.dateFormat = "dd MMM HH:mm"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
    
    return dateString
}

// MARK: - Loading State (Compact)
struct MacroSummaryLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Makroekonomik Veriler")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, AppConstants.screenPadding)
            
            // Loading Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<6, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                            .fill(AppColors.cardBackground)
                            .frame(width: 120, height: 100)
                            .overlay(
                                VStack(alignment: .leading, spacing: 8) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 60, height: 12)
                                        .shimmer(isAnimating: isAnimating)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 50, height: 16)
                                        .shimmer(isAnimating: isAnimating)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 40, height: 10)
                                        .shimmer(isAnimating: isAnimating)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            )
                    }
                }
                .padding(.horizontal, AppConstants.screenPadding)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Error State (Compact)
struct MacroSummaryErrorView: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(AppColors.warning)
            
            Text("Makro veriler yüklenemedi")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
            
            Button("Yenile") {
                onRetry()
            }
            .font(.caption)
            .foregroundColor(AppColors.primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .fill(AppColors.warning.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                        .stroke(AppColors.warning.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, AppConstants.screenPadding)
    }
}