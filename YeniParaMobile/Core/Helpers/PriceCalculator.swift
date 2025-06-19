import Foundation

// MARK: - Price Calculator
final class PriceCalculator {
    // MARK: - Singleton
    static let shared = PriceCalculator()
    
    private init() {}
    
    // MARK: - Price Calculations
    func calculateChange(from oldPrice: Double, to newPrice: Double) -> Double {
        return newPrice - oldPrice
    }
    
    func calculateChangePercent(from oldPrice: Double, to newPrice: Double) -> Double {
        guard oldPrice > 0 else { return 0 }
        return ((newPrice - oldPrice) / oldPrice) * 100
    }
    
    func calculatePriceTarget(currentPrice: Double, changePercent: Double) -> Double {
        return currentPrice * (1 + changePercent / 100)
    }
    
    // MARK: - Investment Calculations
    func calculateInvestmentValue(shares: Double, pricePerShare: Double) -> Double {
        return shares * pricePerShare
    }
    
    func calculateProfit(buyPrice: Double, sellPrice: Double, shares: Double) -> Double {
        return (sellPrice - buyPrice) * shares
    }
    
    func calculateProfitPercent(buyPrice: Double, sellPrice: Double) -> Double {
        guard buyPrice > 0 else { return 0 }
        return ((sellPrice - buyPrice) / buyPrice) * 100
    }
    
    func calculateBreakEvenPrice(buyPrice: Double, commission: Double, shares: Double) -> Double {
        guard shares > 0 else { return buyPrice }
        return buyPrice + (commission * 2 / shares)
    }
    
    // MARK: - Technical Indicators
    func calculateSMA(prices: [Double], period: Int) -> Double? {
        guard prices.count >= period else { return nil }
        let sum = prices.suffix(period).reduce(0, +)
        return sum / Double(period)
    }
    
    func calculateEMA(prices: [Double], period: Int) -> Double? {
        guard prices.count >= period else { return nil }
        
        let multiplier = 2.0 / Double(period + 1)
        var ema = prices.prefix(period).reduce(0, +) / Double(period)
        
        for i in period..<prices.count {
            ema = (prices[i] - ema) * multiplier + ema
        }
        
        return ema
    }
    
    func calculateRSI(prices: [Double], period: Int = 14) -> Double? {
        guard prices.count > period else { return nil }
        
        var gains: [Double] = []
        var losses: [Double] = []
        
        for i in 1..<prices.count {
            let change = prices[i] - prices[i-1]
            if change > 0 {
                gains.append(change)
                losses.append(0)
            } else {
                gains.append(0)
                losses.append(abs(change))
            }
        }
        
        let avgGain = gains.suffix(period).reduce(0, +) / Double(period)
        let avgLoss = losses.suffix(period).reduce(0, +) / Double(period)
        
        guard avgLoss > 0 else { return 100 }
        
        let rs = avgGain / avgLoss
        return 100 - (100 / (1 + rs))
    }
    
    func calculateBollingerBands(prices: [Double], period: Int = 20, stdDev: Double = 2) -> (upper: Double, middle: Double, lower: Double)? {
        guard let sma = calculateSMA(prices: prices, period: period) else { return nil }
        
        let variance = prices.suffix(period).map { pow($0 - sma, 2) }.reduce(0, +) / Double(period)
        let standardDeviation = sqrt(variance)
        
        return (
            upper: sma + (standardDeviation * stdDev),
            middle: sma,
            lower: sma - (standardDeviation * stdDev)
        )
    }
    
    // MARK: - Volume Analysis
    func calculateVWAP(prices: [Double], volumes: [Double]) -> Double? {
        guard prices.count == volumes.count, !prices.isEmpty else { return nil }
        
        var totalPV: Double = 0
        var totalVolume: Double = 0
        
        for i in 0..<prices.count {
            totalPV += prices[i] * volumes[i]
            totalVolume += volumes[i]
        }
        
        guard totalVolume > 0 else { return nil }
        return totalPV / totalVolume
    }
    
    func calculateVolumeRatio(currentVolume: Double, averageVolume: Double) -> Double {
        guard averageVolume > 0 else { return 0 }
        return currentVolume / averageVolume
    }
    
    // MARK: - Risk Calculations
    func calculateVolatility(prices: [Double]) -> Double? {
        guard prices.count > 1 else { return nil }
        
        let returns = (1..<prices.count).map { i in
            log(prices[i] / prices[i-1])
        }
        
        let mean = returns.reduce(0, +) / Double(returns.count)
        let variance = returns.map { pow($0 - mean, 2) }.reduce(0, +) / Double(returns.count - 1)
        
        return sqrt(variance) * sqrt(252) // Annualized volatility
    }
    
    func calculateSharpeRatio(returns: [Double], riskFreeRate: Double = 0.02) -> Double? {
        guard !returns.isEmpty else { return nil }
        
        let avgReturn = returns.reduce(0, +) / Double(returns.count)
        let excessReturn = avgReturn - riskFreeRate
        
        guard let volatility = calculateVolatility(prices: returns), volatility > 0 else { return nil }
        
        return excessReturn / volatility
    }
    
    func calculateMaxDrawdown(prices: [Double]) -> Double? {
        guard prices.count > 1 else { return nil }
        
        var maxDrawdown: Double = 0
        var peak = prices[0]
        
        for price in prices {
            if price > peak {
                peak = price
            }
            let drawdown = (peak - price) / peak
            maxDrawdown = max(maxDrawdown, drawdown)
        }
        
        return maxDrawdown * 100
    }
    
    // MARK: - Portfolio Calculations
    func calculatePortfolioValue(holdings: [(shares: Double, price: Double)]) -> Double {
        return holdings.reduce(0) { $0 + ($1.shares * $1.price) }
    }
    
    func calculatePortfolioAllocation(holdings: [(symbol: String, value: Double)]) -> [(symbol: String, percentage: Double)] {
        let totalValue = holdings.reduce(0) { $0 + $1.value }
        guard totalValue > 0 else { return [] }
        
        return holdings.map { holding in
            (symbol: holding.symbol, percentage: (holding.value / totalValue) * 100)
        }
    }
    
    func calculateDiversificationRatio(allocations: [Double]) -> Double {
        // Herfindahl-Hirschman Index
        let hhi = allocations.map { pow($0 / 100, 2) }.reduce(0, +)
        return 1 / hhi
    }
    
    // MARK: - Commission Calculations
    func calculateCommission(tradeValue: Double, commissionRate: Double = 0.001) -> Double {
        return tradeValue * commissionRate
    }
    
    func calculateNetProfit(grossProfit: Double, buyCommission: Double, sellCommission: Double) -> Double {
        return grossProfit - buyCommission - sellCommission
    }
    
    // MARK: - Price Formatting
    func roundToTick(price: Double, tickSize: Double = 0.01) -> Double {
        return round(price / tickSize) * tickSize
    }
    
    func formatPriceForDisplay(_ price: Double, decimals: Int = 2) -> String {
        return String(format: "%.\(decimals)f", price)
    }
}

// MARK: - Trading Calculator
struct TradingCalculator {
    // Position Sizing
    static func calculatePositionSize(
        accountBalance: Double,
        riskPercentage: Double,
        entryPrice: Double,
        stopLossPrice: Double
    ) -> Int {
        let riskAmount = accountBalance * (riskPercentage / 100)
        let riskPerShare = abs(entryPrice - stopLossPrice)
        
        guard riskPerShare > 0 else { return 0 }
        
        return Int(riskAmount / riskPerShare)
    }
    
    // Risk/Reward Ratio
    static func calculateRiskRewardRatio(
        entryPrice: Double,
        stopLossPrice: Double,
        targetPrice: Double
    ) -> Double? {
        let risk = abs(entryPrice - stopLossPrice)
        let reward = abs(targetPrice - entryPrice)
        
        guard risk > 0 else { return nil }
        
        return reward / risk
    }
    
    // Expected Value
    static func calculateExpectedValue(
        winRate: Double,
        averageWin: Double,
        averageLoss: Double
    ) -> Double {
        let lossRate = 1 - winRate
        return (winRate * averageWin) - (lossRate * averageLoss)
    }
}

// MARK: - Investment Metrics
struct InvestmentMetrics {
    let totalInvested: Double
    let currentValue: Double
    let totalReturn: Double
    let totalReturnPercent: Double
    let annualizedReturn: Double
    let volatility: Double
    let sharpeRatio: Double
    let maxDrawdown: Double
    
    var isPositive: Bool { totalReturn >= 0 }
    
    init(
        totalInvested: Double,
        currentValue: Double,
        startDate: Date,
        endDate: Date = Date(),
        prices: [Double]
    ) {
        self.totalInvested = totalInvested
        self.currentValue = currentValue
        self.totalReturn = currentValue - totalInvested
        self.totalReturnPercent = PriceCalculator.shared.calculateProfitPercent(
            buyPrice: totalInvested,
            sellPrice: currentValue
        )
        
        // Calculate annualized return
        let days = Double(Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0)
                let years = days / 365.25
                if years > 0 && totalInvested > 0 {
                    self.annualizedReturn = pow(currentValue / totalInvested, 1 / years) - 1
                } else {
                    self.annualizedReturn = 0
                }
        
        // Calculate other metrics
        self.volatility = PriceCalculator.shared.calculateVolatility(prices: prices) ?? 0
        self.sharpeRatio = PriceCalculator.shared.calculateSharpeRatio(returns: prices) ?? 0
        self.maxDrawdown = PriceCalculator.shared.calculateMaxDrawdown(prices: prices) ?? 0
    }
}
