import Foundation
import SwiftUI

// MARK: - SP100 Symbols Response

struct SP100SymbolsResponse: Codable {
    let data: SP100SymbolsData
    let success: Bool
}

struct SP100SymbolsData: Codable {
    let count: Int
    let market: MarketInfo?
    let symbols: [SP100Symbol]
}

struct MarketInfo: Codable {
    let currentTime: String
    let isOpen: Bool
    let status: String // open, closed, pre-market, after-hours
    let timezone: String
    
    enum CodingKeys: String, CodingKey {
        case currentTime = "current_time"
        case isOpen = "is_open"
        case status
        case timezone
    }
}

struct SP100Symbol: Codable, Identifiable {
    var id: String { code }
    
    let code: String
    let name: String
    let sector: String
    let industry: String
    let logoPath: String
    let latestPrice: Double
    let dayOpen: Double
    let dayHigh: Double
    let dayLow: Double
    let dayClose: Double
    let prevClose: Double
    let changePercent: Double
    let volume: Int64
    let lastUpdated: String
    
    enum CodingKeys: String, CodingKey {
        case code
        case name
        case sector
        case industry
        case logoPath = "logo_path"
        case latestPrice = "latest_price"
        case dayOpen = "day_open"
        case dayHigh = "day_high"
        case dayLow = "day_low"
        case dayClose = "day_close"
        case prevClose = "prev_close"
        case changePercent = "change_percent"
        case volume
        case lastUpdated = "last_updated"
    }
    
    var change: Double {
        latestPrice - prevClose
    }
    
    var formattedPrice: String {
        String(format: "$%.2f", latestPrice)
    }
    
    var formattedChange: String {
        return "\(String(format: "%.2f%%", abs(changePercent)))"
    }
    
    var isPositive: Bool {
        changePercent >= 0
    }
}

// MARK: - Stock Quote Response

struct StockQuoteResponse: Codable {
    let data: StockQuote
    let success: Bool
}

struct StockQuote: Codable {
    let symbol: String
    let logoPath: String?
    let latestPrice: Double?
    let price: Double
    let open: Double
    let high: Double
    let low: Double
    let prevClose: Double
    let change: Double
    let changePercent: Double
    let volume: Int64
    let bidPrice: Double
    let bidSize: Int
    let askPrice: Double
    let askSize: Int
    let timestamp: String
    let fundamentals: Fundamentals?
    
    enum CodingKeys: String, CodingKey {
        case symbol
        case logoPath = "logo_path"
        case latestPrice = "latest_price"
        case price
        case open
        case high
        case low
        case prevClose = "prev_close"
        case change
        case changePercent = "change_percent"
        case volume
        case bidPrice = "bid_price"
        case bidSize = "bid_size"
        case askPrice = "ask_price"
        case askSize = "ask_size"
        case timestamp
        case fundamentals
    }
}

// MARK: - Fundamentals
struct Fundamentals: Codable {
    let beta: Double?
    let ceo: String?
    let currentRatio: Double?
    let debtToEquity: Double?
    let description: String?
    let dividendYield: Double?
    let employees: Int?
    let eps: Double?
    let grossProfitMargin: Double?
    let marketCap: Double?
    let netMargin: Double?
    let operatingMargin: Double?
    let pbRatio: Double?
    let peRatio: Double?
    let psRatio: Double?
    let roa: Double?
    let roe: Double?
    let website: String?
    
    enum CodingKeys: String, CodingKey {
        case beta
        case ceo
        case currentRatio = "current_ratio"
        case debtToEquity = "debt_to_equity"
        case description
        case dividendYield = "dividend_yield"
        case employees
        case eps
        case grossProfitMargin = "gross_profit_margin"
        case marketCap = "market_cap"
        case netMargin = "net_margin"
        case operatingMargin = "operating_margin"
        case pbRatio = "pb_ratio"
        case peRatio = "pe_ratio"
        case psRatio = "ps_ratio"
        case roa
        case roe
        case website
    }
}

// MARK: - StockQuote Extensions
extension StockQuote {
    var formattedPrice: String {
        String(format: "$%.2f", latestPrice ?? price)
    }
    
    var formattedChangePercent: String {
        let sign = changePercent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", changePercent))%"
    }
    
    var isPositive: Bool {
        changePercent >= 0
    }
    
    var changeColor: Color {
        isPositive ? AppColors.primary : AppColors.error
    }
}

// MARK: - Stock Snapshot Response

struct StockSnapshotResponse: Codable {
    let data: StockSnapshot
    let success: Bool
}

struct StockSnapshot: Codable {
    let symbol: String
    let name: String
    let sector: String
    let industry: String
    let quote: StockQuote
    let dailyBars: [DailyBar]
    
    enum CodingKeys: String, CodingKey {
        case symbol
        case name
        case sector
        case industry
        case quote
        case dailyBars = "daily_bars"
    }
}

// MARK: - Daily Bars Response

struct DailyBarsResponse: Codable {
    let data: DailyBarsData
    let success: Bool
}

struct DailyBarsData: Codable {
    let bars: [DailyBar]
}

struct DailyBar: Codable, Identifiable {
    var id: String { date }
    
    let date: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int64
    let vwap: Double
    let tradeCount: Int
    
    enum CodingKeys: String, CodingKey {
        case date
        case open
        case high
        case low
        case close
        case volume
        case vwap
        case tradeCount = "trade_count"
    }
}

// MARK: - Minute Bars Response

struct MinuteBarsResponse: Codable {
    let data: MinuteBarsData
    let success: Bool
}

struct MinuteBarsData: Codable {
    let bars: [MinuteBar]
}

struct MinuteBar: Codable, Identifiable {
    var id: String { timestamp }
    
    let timestamp: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int64
    let vwap: Double
    let tradeCount: Int
    
    enum CodingKeys: String, CodingKey {
        case timestamp
        case open
        case high
        case low
        case close
        case volume
        case vwap
        case tradeCount = "trade_count"
    }
}

// MARK: - Chart Data Response

struct ChartDataResponse: Codable {
    let data: ChartData
    let success: Bool
}

struct ChartData: Codable {
    let bars: [ChartBar]
}

struct ChartBar: Codable {
    let timestamp: String?
    let date: String?
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int64
    let vwap: Double?
    let tradeCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case timestamp
        case date
        case open
        case high
        case low
        case close
        case volume
        case vwap
        case tradeCount = "trade_count"
    }
    
    var dateTime: String {
        timestamp ?? date ?? ""
    }
}

// MARK: - Market Indices

struct MarketIndex {
    let name: String
    let value: String
    let change: Double
    let changePercent: Double
    let icon: String
    
    var isPositive: Bool {
        change >= 0
    }
    
    var formattedChange: String {
        return "\(String(format: "%.2f%%", abs(changePercent)))"
    }
}

// MARK: - Metrics Info Response

struct MetricsInfoResponse: Codable {
    let data: MetricsInfoData
    let success: Bool
}

struct MetricsInfoData: Codable {
    let categories: [String]
    let metrics: [MetricInfo]
}

struct MetricInfo: Codable, Identifiable {
    let id = UUID()
    let key: String
    let name: String
    let description: String
    let ifIncreases: String
    let ifDecreases: String
    let goodRange: String?
    let category: String
    
    enum CodingKeys: String, CodingKey {
        case key
        case name
        case description
        case ifIncreases = "if_increases"
        case ifDecreases = "if_decreases"
        case goodRange = "good_range"
        case category
    }
}