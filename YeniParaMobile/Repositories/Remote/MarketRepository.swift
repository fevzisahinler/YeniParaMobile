import Foundation
import Combine

// MARK: - Market Repository Protocol
protocol MarketRepositoryProtocol {
    func getAllSymbols(page: Int, limit: Int) async throws -> [Symbol]
    func searchSymbols(query: String) async throws -> [Symbol]
    func getFundamentalData(symbol: String) async throws -> FundamentalData
    func getCandleData(symbol: String, timeframe: String, from: String?, to: String?) async throws -> CandleResponse
    func getWatchlist() async throws -> [String]
    func addToWatchlist(symbol: String) async throws
    func removeFromWatchlist(symbol: String) async throws
}

// MARK: - Market Repository Implementation
final class MarketRepository: BaseRepository<Symbol>, MarketRepositoryProtocol, CacheableRepositoryProtocol {
    // MARK: - Properties
    static let shared = MarketRepository()
    
    let apiClient: APIClient
    let cacheManager: CacheManager
    let cacheExpiry: TimeInterval = 300 // 5 minutes
    
    private let watchlistKey = "user_watchlist"
    private var watchlistSubject = CurrentValueSubject<Set<String>, Never>([])
    
    var watchlistPublisher: AnyPublisher<Set<String>, Never> {
        watchlistSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    init(apiClient: APIClient = .shared, cacheManager: CacheManager = .shared) {
        self.apiClient = apiClient
        self.cacheManager = cacheManager
        super.init()
        
        loadWatchlist()
    }
    
    // MARK: - Symbol Methods
    func getAllSymbols(page: Int = 1, limit: Int = 100) async throws -> [Symbol] {
        let cacheKey = "symbols_\(page)_\(limit)"
        
        // Check cache
        if let cached: [Symbol] = await getCached(key: cacheKey) {
            notifyUpdate(cached)
            return cached
        }
        
        // Fetch from API
        let response: SymbolsResponse = try await apiClient.request(
            MarketEndpoint.getSymbols(page: page, limit: limit, sort: "code", order: "asc")
        )
        
        guard response.success else {
            throw RepositoryError.notFound
        }
        
        // Cache and notify
        await setCached(response.data, key: cacheKey)
        notifyUpdate(response.data)
        
        return response.data
    }
    
    func searchSymbols(query: String) async throws -> [Symbol] {
        guard !query.isEmpty else { return [] }
        
        let response: SymbolsResponse = try await apiClient.request(
            MarketEndpoint.searchSymbols(query: query)
        )
        
        guard response.success else {
            throw RepositoryError.notFound
        }
        
        return response.data
    }
    
    func getFundamentalData(symbol: String) async throws -> FundamentalData {
        let cacheKey = "fundamental_\(symbol)"
        
        // Check cache
        if let cached: FundamentalData = await getCached(key: cacheKey) {
            return cached
        }
        
        // Fetch from API
        let response: FundamentalResponse = try await apiClient.request(
            MarketEndpoint.getFundamentalData(symbol: symbol)
        )
        
        guard response.success else {
            throw RepositoryError.notFound
        }
        
        // Cache for 1 hour
        await cacheManager.set(response.data, key: cacheKey, expiry: 3600)
        
        return response.data
    }
    
    func getCandleData(symbol: String, timeframe: String, from: String? = nil, to: String? = nil) async throws -> CandleResponse {
        // Don't cache candle data as it's time-sensitive
        let response: CandleResponse = try await apiClient.request(
            MarketEndpoint.getCandleData(
                symbol: symbol,
                timeframe: timeframe,
                from: from,
                to: to
            )
        )
        
        return response
    }
    
    // MARK: - Watchlist Methods
    func getWatchlist() async throws -> [String] {
        return Array(watchlistSubject.value)
    }
    
    func addToWatchlist(symbol: String) async throws {
        var watchlist = watchlistSubject.value
        watchlist.insert(symbol)
        
        // Save to local storage
        UserDefaultsRepository.shared.set(Array(watchlist), for: watchlistKey)
        
        // Update publisher
        watchlistSubject.send(watchlist)
        
        // Optionally sync with server
        await syncWatchlist()
    }
    
    func removeFromWatchlist(symbol: String) async throws {
        var watchlist = watchlistSubject.value
        watchlist.remove(symbol)
        
        // Save to local storage
        UserDefaultsRepository.shared.set(Array(watchlist), for: watchlistKey)
        
        // Update publisher
        watchlistSubject.send(watchlist)
        
        // Optionally sync with server
        await syncWatchlist()
    }
    
    // MARK: - Cache Methods
    func getCached<T: Codable>(key: String) async -> T? {
        return await cacheManager.get(key: key)
    }
    
    func setCached<T: Codable>(_ entity: T, key: String) async {
        await cacheManager.set(entity, key: key, expiry: cacheExpiry)
    }
    
    func invalidateCache(key: String) async {
        await cacheManager.remove(key: key)
    }
    
    // MARK: - Private Methods
    private func loadWatchlist() {
        if let saved = UserDefaultsRepository.shared.get([String].self, for: watchlistKey) {
            watchlistSubject.send(Set(saved))
        }
    }
    
    private func syncWatchlist() async {
        // Implement server sync if needed
        // This could involve calling a watchlist API endpoint
    }
}

// MARK: - Market Data Aggregator
final class MarketDataAggregator {
    static let shared = MarketDataAggregator()
    
    private let marketRepository: MarketRepositoryProtocol
    private let priceUpdateService = PriceUpdateService.shared
    
    init(marketRepository: MarketRepositoryProtocol = MarketRepository.shared) {
        self.marketRepository = marketRepository
    }
    
    func getEnhancedSymbols(page: Int = 1, limit: Int = 100) async throws -> [EnhancedSymbol] {
        let symbols = try await marketRepository.getAllSymbols(page: page, limit: limit)
        
        // Combine with price updates
        var enhancedSymbols: [EnhancedSymbol] = []
        
        for symbol in symbols {
            var enhanced = EnhancedSymbol(symbol: symbol)
            
            // Get latest price data if available
            if let priceData = PriceUpdateService.shared.getLatestPrice(for: symbol.code) {
                enhanced.currentPrice = priceData.price
                enhanced.change = priceData.change
                enhanced.changePercent = priceData.changePercent
                enhanced.volume = priceData.volume
            }
            
            enhancedSymbols.append(enhanced)
        }
        
        return enhancedSymbols
    }
    
    func getMarketOverview() async throws -> MarketOverview {
        let symbols = try await marketRepository.getAllSymbols(page: 1, limit: 1000)
        
        let gainers = symbols
            .compactMap { symbol -> (Symbol, Double)? in
                guard let priceData = PriceUpdateService.shared.getLatestPrice(for: symbol.code),
                      priceData.changePercent > 0 else { return nil }
                return (symbol, priceData.changePercent)
            }
            .sorted { $0.1 > $1.1 }
            .prefix(10)
            .map { $0.0 }
        
        let losers = symbols
            .compactMap { symbol -> (Symbol, Double)? in
                guard let priceData = PriceUpdateService.shared.getLatestPrice(for: symbol.code),
                      priceData.changePercent < 0 else { return nil }
                return (symbol, priceData.changePercent)
            }
            .sorted { $0.1 < $1.1 }
            .prefix(10)
            .map { $0.0 }
        
        let mostActive = symbols
            .compactMap { symbol -> (Symbol, Int64)? in
                guard let priceData = PriceUpdateService.shared.getLatestPrice(for: symbol.code) else { return nil }
                return (symbol, priceData.volume)
            }
            .sorted { $0.1 > $1.1 }
            .prefix(10)
            .map { $0.0 }
        
        return MarketOverview(
            totalSymbols: symbols.count,
            topGainers: Array(gainers),
            topLosers: Array(losers),
            mostActive: Array(mostActive),
            marketStatus: .open,
            lastUpdate: Date()
        )
    }
}

// MARK: - Supporting Types
struct EnhancedSymbol {
    let symbol: Symbol
    var currentPrice: Double = 0
    var change: Double = 0
    var changePercent: Double = 0
    var volume: Int64 = 0
    
    var isPositive: Bool { changePercent >= 0 }
}

struct MarketOverview {
    let totalSymbols: Int
    let topGainers: [Symbol]
    let topLosers: [Symbol]
    let mostActive: [Symbol]
    let marketStatus: MarketStatus
    let lastUpdate: Date
    
    enum MarketStatus {
        case open, closed, preMarket, afterHours
    }
}

// MARK: - Price Update Service Extension
extension PriceUpdateService {
    func getLatestPrice(for symbol: String) -> PriceUpdate? {
        // This would return cached price data
        // Implementation depends on how PriceUpdateService stores data
        return nil
    }
}
