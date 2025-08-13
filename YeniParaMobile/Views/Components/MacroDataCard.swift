import SwiftUI

// MARK: - Compact Macro Card (New Design)
struct CompactMacroCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    let icon: String
    let color: Color
    
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
                Image(systemName: change == "0.00" || change == "+0.00" || change == "0.00%" ? "minus" : (isPositive ? "arrow.up.right" : "arrow.down.right"))
                    .font(.system(size: 10, weight: .bold))
                
                Text(change)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(change == "0.00" || change == "+0.00" || change == "0.00%" ? AppColors.textSecondary : (isPositive ? AppColors.success : AppColors.error))
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
                        color: AppColors.primary
                    )
                    .onTapGesture { onNavigateToDetail(.gdp) }
                    
                    // CPI Card
                    CompactMacroCard(
                        title: "Enflasyon",
                        value: formatCPIValue(macroData.cpi.value),
                        change: formatPercent(macroData.cpi.yoyInflation),
                        isPositive: macroData.cpi.yoyInflation <= 2.5,
                        icon: "cart.fill",
                        color: Color.orange
                    )
                    .onTapGesture { onNavigateToDetail(.cpi) }
                    
                    // Fed Rate Card
                    CompactMacroCard(
                        title: "Fed Faiz",
                        value: formatRateValue(macroData.fedRate.rate),
                        change: formatChange(macroData.fedRate.change),
                        isPositive: macroData.fedRate.change <= 0,
                        icon: "percent",
                        color: Color.purple
                    )
                    .onTapGesture { onNavigateToDetail(.fedRate) }
                    
                    // Unemployment Card
                    CompactMacroCard(
                        title: "İşsizlik",
                        value: formatRateValue(macroData.unemployment.rate),
                        change: formatChange(macroData.unemployment.change),
                        isPositive: macroData.unemployment.change <= 0,
                        icon: "person.3.fill",
                        color: Color.green
                    )
                    .onTapGesture { onNavigateToDetail(.unemployment) }
                    
                    // Oil Price Card
                    CompactMacroCard(
                        title: "Petrol",
                        value: "$\(String(format: "%.2f", macroData.oilPrice.price))",
                        change: formatPercent(macroData.oilPrice.percentChange),
                        isPositive: macroData.oilPrice.change >= 0,
                        icon: "drop.fill",
                        color: Color.brown
                    )
                    .onTapGesture { onNavigateToDetail(.oil) }
                    
                    // Retail Sales Card
                    CompactMacroCard(
                        title: "Perakende",
                        value: formatRetailValueCompact(macroData.retailSales.value),
                        change: formatPercent(macroData.retailSales.yoyChange),
                        isPositive: macroData.retailSales.yoyChange >= 0,
                        icon: "bag.fill",
                        color: Color.pink
                    )
                    .onTapGesture { onNavigateToDetail(.retailSales) }
                }
                .padding(.horizontal, AppConstants.screenPadding)
            }
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