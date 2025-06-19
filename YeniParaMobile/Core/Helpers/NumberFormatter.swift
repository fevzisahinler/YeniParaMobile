import Foundation

// MARK: - Number Formatter Helper
final class NumberFormatterHelper {
    // MARK: - Singleton
    static let shared = NumberFormatterHelper()
    
    // MARK: - Formatters
    private lazy var currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    private lazy var percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.multiplier = 1 // Don't multiply by 100
        return formatter
    }()
    
    private lazy var decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    private lazy var integerFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    private lazy var abbreviatedFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Currency Formatting
    func formatCurrency(_ value: Double) -> String {
        return currencyFormatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
    
    func formatCurrency(_ value: Decimal) -> String {
        return currencyFormatter.string(from: value as NSNumber) ?? "$0.00"
    }
    
    func formatCurrencyChange(_ value: Double) -> String {
        let formatted = formatCurrency(abs(value))
        return value >= 0 ? "+\(formatted)" : "-\(formatted)"
    }
    
    // MARK: - Percentage Formatting
    func formatPercentage(_ value: Double) -> String {
        return percentFormatter.string(from: NSNumber(value: value)) ?? "0.00%"
    }
    
    func formatPercentageChange(_ value: Double) -> String {
        let formatted = formatPercentage(abs(value))
        return value >= 0 ? "+\(formatted)" : "-\(formatted)"
    }
    
    // MARK: - Number Formatting
    func formatDecimal(_ value: Double) -> String {
        return decimalFormatter.string(from: NSNumber(value: value)) ?? "0.00"
    }
    
    func formatInteger(_ value: Int) -> String {
        return integerFormatter.string(from: NSNumber(value: value)) ?? "0"
    }
    
    func formatInteger(_ value: Int64) -> String {
        return integerFormatter.string(from: NSNumber(value: value)) ?? "0"
    }
    
    // MARK: - Abbreviated Number Formatting
    func formatAbbreviated(_ value: Double) -> String {
        let sign = value < 0 ? "-" : ""
        let absValue = abs(value)
        
        switch absValue {
        case 1_000_000_000_000...:
            return "\(sign)\(abbreviatedFormatter.string(from: NSNumber(value: absValue / 1_000_000_000_000)) ?? "0")T"
        case 1_000_000_000...:
            return "\(sign)\(abbreviatedFormatter.string(from: NSNumber(value: absValue / 1_000_000_000)) ?? "0")B"
        case 1_000_000...:
            return "\(sign)\(abbreviatedFormatter.string(from: NSNumber(value: absValue / 1_000_000)) ?? "0")M"
        case 1_000...:
            return "\(sign)\(abbreviatedFormatter.string(from: NSNumber(value: absValue / 1_000)) ?? "0")K"
        default:
            return "\(sign)\(integerFormatter.string(from: NSNumber(value: absValue)) ?? "0")"
        }
    }
    
    func formatVolume(_ value: Int64) -> String {
        return formatAbbreviated(Double(value))
    }
    
    func formatMarketCap(_ value: Double) -> String {
        if value == 0 { return "N/A" }
        return formatAbbreviated(value)
    }
    
    // MARK: - Custom Formatting
    func formatPrice(_ price: Double, includeSign: Bool = false) -> String {
        if price == 0 { return "N/A" }
        
        let formatted = formatCurrency(price)
        
        if includeSign && price > 0 {
            return "+\(formatted)"
        }
        
        return formatted
    }
    
    func formatPriceRange(low: Double, high: Double) -> String {
        if low == 0 || high == 0 { return "N/A" }
        return "\(formatCurrency(low)) - \(formatCurrency(high))"
    }
    
    func formatPERatio(_ ratio: Double?) -> String {
        guard let ratio = ratio, ratio > 0 else { return "N/A" }
        return String(format: "%.2f", ratio)
    }
    
    func formatDividendYield(_ yield: Double?) -> String {
        guard let yield = yield, yield > 0 else { return "0%" }
        return formatPercentage(yield)
    }
}

// MARK: - Convenience Extensions
extension Double {
    var formattedCurrency: String {
        NumberFormatterHelper.shared.formatCurrency(self)
    }
    
    var formattedCurrencyChange: String {
        NumberFormatterHelper.shared.formatCurrencyChange(self)
    }
    
    var formattedPercentage: String {
        NumberFormatterHelper.shared.formatPercentage(self)
    }
    
    var formattedPercentageChange: String {
        NumberFormatterHelper.shared.formatPercentageChange(self)
    }
    
    var formattedDecimal: String {
        NumberFormatterHelper.shared.formatDecimal(self)
    }
    
    var formattedAbbreviated: String {
        NumberFormatterHelper.shared.formatAbbreviated(self)
    }
}

extension Int {
    var formattedInteger: String {
        NumberFormatterHelper.shared.formatInteger(self)
    }
}

extension Int64 {
    var formattedVolume: String {
        NumberFormatterHelper.shared.formatVolume(self)
    }
}
