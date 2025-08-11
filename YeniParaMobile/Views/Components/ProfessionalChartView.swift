import SwiftUI
import Charts

struct ProfessionalChartView: View {
    let candles: [DetailCandleData]
    let selectedTimeframe: TimeFrame
    let currentPrice: Double
    let priceChange: Double
    let changePercent: Double
    
    private var minPrice: Double {
        candles.map { $0.low }.min() ?? 0
    }
    
    private var maxPrice: Double {
        candles.map { $0.high }.max() ?? 100
    }
    
    private var priceRange: Double {
        maxPrice - minPrice
    }
    
    private var isPositive: Bool {
        changePercent >= 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Price Header
            VStack(alignment: .leading, spacing: 4) {
                Text(formatPrice(currentPrice))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: 8) {
                    Text(formatChange(priceChange))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isPositive ? AppColors.success : AppColors.error)
                    
                    Text("(\(formatPercent(changePercent)))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isPositive ? AppColors.success : AppColors.error)
                }
            }
            .padding(.horizontal, 20)
            
            // Chart
            if !candles.isEmpty {
                Chart(candles) { candle in
                    if selectedTimeframe == .oneDay {
                        // Line chart for intraday
                        LineMark(
                            x: .value("Time", candle.timestamp),
                            y: .value("Price", candle.close)
                        )
                        .foregroundStyle(isPositive ? AppColors.success : AppColors.error)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        
                        AreaMark(
                            x: .value("Time", candle.timestamp),
                            y: .value("Price", candle.close)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    (isPositive ? AppColors.success : AppColors.error).opacity(0.3),
                                    (isPositive ? AppColors.success : AppColors.error).opacity(0.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    } else {
                        // Candlestick for longer timeframes
                        RectangleMark(
                            x: .value("Date", candle.timestamp),
                            yStart: .value("Low", candle.low),
                            yEnd: .value("High", candle.high),
                            width: 1
                        )
                        .foregroundStyle(Color.gray.opacity(0.5))
                        
                        RectangleMark(
                            x: .value("Date", candle.timestamp),
                            yStart: .value("Open", min(candle.open, candle.close)),
                            yEnd: .value("Close", max(candle.open, candle.close)),
                            width: .ratio(0.6)
                        )
                        .foregroundStyle(candle.close >= candle.open ? AppColors.success : AppColors.error)
                    }
                }
                .frame(height: 300)
                .chartYScale(domain: (minPrice * 0.98)...(maxPrice * 1.02))
                .chartXAxis {
                    AxisMarks(preset: .aligned, position: .bottom) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(formatAxisDate(date))
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(preset: .aligned, position: .leading) { value in
                        if let price = value.as(Double.self) {
                            AxisValueLabel {
                                Text(formatAxisPrice(price))
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                                .foregroundStyle(AppColors.cardBorder.opacity(0.3))
                        }
                    }
                }
                .padding(.horizontal, 20)
            } else {
                // Loading or empty state
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                    Text("Grafik yükleniyor...")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(height: 300)
                .frame(maxWidth: .infinity)
            }
            
            // Volume bars (optional)
            if !candles.isEmpty && candles.first?.volume ?? 0 > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hacim")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, 20)
                    
                    Chart(candles) { candle in
                        BarMark(
                            x: .value("Time", candle.timestamp),
                            y: .value("Volume", candle.volume)
                        )
                        .foregroundStyle(AppColors.primary.opacity(0.3))
                    }
                    .frame(height: 60)
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(preset: .aligned, position: .leading) { value in
                            if let volume = value.as(Double.self) {
                                AxisValueLabel {
                                    Text(formatVolume(volume))
                                        .font(.caption2)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .padding(.vertical, 16)
        .background(AppColors.cardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Helper Functions
    
    private func formatPrice(_ price: Double) -> String {
        if price == 0 { return "$0.00" }
        return "$\(String(format: "%.2f", price))"
    }
    
    private func formatChange(_ change: Double) -> String {
        let sign = change >= 0 ? "+" : ""
        return "\(sign)$\(String(format: "%.2f", abs(change)))"
    }
    
    private func formatPercent(_ percent: Double) -> String {
        let sign = percent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", percent))%"
    }
    
    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        switch selectedTimeframe {
        case .oneHour, .oneDay:
            formatter.dateFormat = "HH:mm"
        case .oneWeek, .oneMonth:
            formatter.dateFormat = "dd MMM"
        case .threeMonths, .oneYear:
            formatter.dateFormat = "MMM"
        }
        
        return formatter.string(from: date)
    }
    
    private func formatAxisPrice(_ price: Double) -> String {
        if price >= 1000 {
            return "$\(String(format: "%.0f", price))"
        } else if price >= 100 {
            return "$\(String(format: "%.1f", price))"
        } else {
            return "$\(String(format: "%.2f", price))"
        }
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
}