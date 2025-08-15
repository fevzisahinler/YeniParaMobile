import Foundation

// Shared cache for market data to ensure consistency
@MainActor
final class MarketDataCache: ObservableObject {
    static let shared = MarketDataCache()
    
    @Published var cachedQuotes: [String: StockQuoteData] = [:]
    @Published var lastUpdateTime: Date?
    
    private let cacheExpiration: TimeInterval = 60.0 // 60 seconds
    
    private init() {}
    
    func getCachedQuote(for symbol: String) -> StockQuoteData? {
        guard let quote = cachedQuotes[symbol],
              let lastUpdate = lastUpdateTime,
              Date().timeIntervalSince(lastUpdate) < cacheExpiration else {
            return nil
        }
        return quote
    }
    
    func updateQuote(symbol: String, quote: StockQuoteData) {
        cachedQuotes[symbol] = quote
        lastUpdateTime = Date()
    }
    
    func updateBulkQuotes(_ quotes: [String: StockQuoteData]) {
        cachedQuotes.merge(quotes) { _, new in new }
        lastUpdateTime = Date()
    }
    
    func clearCache() {
        cachedQuotes.removeAll()
        lastUpdateTime = nil
    }
}

// Data model for cached stock quote
struct StockQuoteData {
    let symbol: String
    let latestPrice: Double
    let change: Double
    let changePercent: Double
    let open: Double
    let high: Double
    let low: Double
    let prevClose: Double
    let volume: Int64
    let timestamp: Date
    let logoPath: String?
}