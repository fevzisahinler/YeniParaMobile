import Foundation
import Combine

// MARK: - Market Service Protocol
protocol MarketServiceProtocol {
    func getSymbols(page: Int, limit: Int, sort: String, order: String) async throws -> [Symbol]
    func searchSymbols(query: String) async throws -> [Symbol]
    func getFundamentalData(symbol: String) async throws -> FundamentalData
    func getCandleData(symbol: String, timeframe: String, from: String?, to: String?) async throws -> CandleResponse
    func getCompanyLogo(symbol: String) async throws -> Data
    func getMarketStatus() async throws -> MarketStatus
    func getTopMovers(type: MarketEndpoint.MoverType) async throws -> [Symbol]
    
    // Real-time updates
    var symbolsPublisher: AnyPublisher<[Symbol], Never> { get }
}

// MARK: - Market Service Implementation
final class MarketService: MarketServiceProtocol {
    // MARK: - Properties
    static let shared = MarketService()
    
    private let apiClient: APIClient
    private let cacheManager: CacheManager
    private let refreshInterval: TimeInterval = 30.0
    
    private let symbolsSubject = CurrentValueSubject<[Symbol], Never>([])
    var symbolsPublisher: AnyPublisher<[Symbol], Never> {
        symbolsSubject.eraseToAnyPublisher()
    }
    
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(apiClient: APIClient = .shared, cacheManager: CacheManager = .shared) {
        self.apiClient = apiClient
        self.cacheManager = cacheManager
        
        startAutoRefresh()
    }
    
    deinit {
        stopAutoRefresh()
    }
    
    // MARK: - Public Methods
    func getSymbols(page: Int = 1, limit: Int = 100, sort: String = "code", order: String = "asc") async throws -> [Symbol] {
        // Check cache first
        let cacheKey = "symbols_\(page)_\(limit)_\(sort)_\(order)"
        if let cached: SymbolsResponse = await cacheManager.get(key: cacheKey) {
            symbolsSubject.send(cached.data)
            return cached.data
        }
        
        // Fetch from API
        let response: SymbolsResponse = try await apiClient.request(
            MarketEndpoint.getSymbols(page: page, limit: limit, sort: sort, order: order)
        )
        
        guard response.success else {
            throw MarketError.fetchSymbolsFailed
        }
        
        // Cache the response
        await cacheManager.set(response, key: cacheKey, expiry: 300) // 5 minutes
        
        // Update publisher
        symbolsSubject.send(response.data)
        
        return response.data
    }
    
    func searchSymbols(query: String) async throws -> [Symbol] {
        guard !query.isEmpty else { return [] }
        
        let response: SymbolsResponse = try await apiClient.request(
            MarketEndpoint.searchSymbols(query: query)
        )
        
        guard response.success else {
            throw MarketError.searchFailed
        }
        
        return response.data
    }
    
    func getFundamentalData(symbol: String) async throws -> FundamentalData {
        // Check cache first
        let cacheKey = "fundamental_\(symbol)"
        if let cached: FundamentalResponse = await cacheManager.get(key: cacheKey) {
            return cached.data
        }
        
        // Fetch from API
        let response: FundamentalResponse = try await apiClient.request(
            MarketEndpoint.getFundamentalData(symbol: symbol)
        )
        
        guard response.success else {
            throw MarketError.fetchFundamentalsFailed
        }
        
        // Cache for 1 hour
        await cacheManager.set(response, key: cacheKey, expiry: 3600)
        
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
    
    func getCompanyLogo(symbol: String) async throws -> Data {
        // Check image cache first
        let cacheKey = "logo_\(symbol)"
        if let cachedData = await cacheManager.getImage(key: cacheKey) {
            return cachedData
        }
        
        // Fetch from API
        let logoData = try await apiClient.requestData(
            MarketEndpoint.getCompanyLogo(symbol: symbol)
        )
        
        // Cache image for 24 hours
        await cacheManager.setImage(logoData, key: cacheKey, expiry: 86400)
        
        return logoData
    }
    
    func getMarketStatus() async throws -> MarketStatus {
        // Implement market status endpoint
        throw MarketError.notImplemented
    }
    
    func getTopMovers(type: MarketEndpoint.MoverType) async throws -> [Symbol] {
        // Implement top movers endpoint
        throw MarketError.notImplemented
    }
    
    // MARK: - Private Methods
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { _ in
            Task { [weak self] in
                try? await self?.refreshSymbols()
            }
        }
    }
    
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func refreshSymbols() async throws {
        let symbols = try await getSymbols()
        symbolsSubject.send(symbols)
    }
}

// MARK: - Market Errors
enum MarketError: LocalizedError {
    case fetchSymbolsFailed
    case searchFailed
    case fetchFundamentalsFailed
    case fetchCandlesFailed
    case logoNotFound
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .fetchSymbolsFailed:
            return "Hisse senetleri yüklenemedi"
        case .searchFailed:
            return "Arama başarısız oldu"
        case .fetchFundamentalsFailed:
            return "Temel veriler yüklenemedi"
        case .fetchCandlesFailed:
            return "Grafik verileri yüklenemedi"
        case .logoNotFound:
            return "Logo bulunamadı"
        case .notImplemented:
            return "Bu özellik henüz mevcut değil"
        }
    }
}

// MARK: - Market Status Model
struct MarketStatus: Codable {
    let isOpen: Bool
    let nextOpen: Date?
    let nextClose: Date?
    let message: String
}

// MARK: - Price Update Service
final class PriceUpdateService {
    static let shared = PriceUpdateService()
    
    private let updateInterval: TimeInterval = 5.0
    private var timer: Timer?
    private var mockPrices: [String: PriceData] = [:]
    
    private let priceUpdatesSubject = PassthroughSubject<PriceUpdate, Never>()
    var priceUpdates: AnyPublisher<PriceUpdate, Never> {
        priceUpdatesSubject.eraseToAnyPublisher()
    }
    
    struct PriceData {
        let basePrice: Double
        var currentPrice: Double
        var change: Double
        var changePercent: Double
        var volume: Int64
        var high: Double
        var low: Double
    }
    
    struct PriceUpdate {
        let symbol: String
        let price: Double
        let change: Double
        let changePercent: Double
        let volume: Int64
    }
    
    func startMockUpdates(for symbols: [Symbol]) {
        // Initialize mock prices
        symbols.forEach { symbol in
            let basePrice = Double.random(in: 50...500)
            mockPrices[symbol.code] = PriceData(
                basePrice: basePrice,
                currentPrice: basePrice,
                change: 0,
                changePercent: 0,
                volume: Int64.random(in: 100_000...50_000_000),
                high: basePrice,
                low: basePrice
            )
        }
        
        // Start timer for updates
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            self.generatePriceUpdates()
        }
    }
    
    func stopUpdates() {
        timer?.invalidate()
        timer = nil
        mockPrices.removeAll()
    }
    
    
    private func generatePriceUpdates() {
        // Randomly update some prices
        let symbolsToUpdate = mockPrices.keys.shuffled().prefix(Int.random(in: 5...20))
        
        symbolsToUpdate.forEach { symbol in
            guard var priceData = mockPrices[symbol] else { return }
            
            // Generate realistic price movement
            let changePercent = Double.random(in: -0.5...0.5)
            let newPrice = priceData.basePrice * (1 + changePercent / 100)
            
            priceData.currentPrice = newPrice
            priceData.change = newPrice - priceData.basePrice
            priceData.changePercent = (priceData.change / priceData.basePrice) * 100
            priceData.volume += Int64.random(in: 10_000...100_000)
            priceData.high = max(priceData.high, newPrice)
            priceData.low = min(priceData.low, newPrice)
            
            mockPrices[symbol] = priceData
            
            // Send update
            let update = PriceUpdate(
                symbol: symbol,
                price: newPrice,
                change: priceData.change,
                changePercent: priceData.changePercent,
                volume: priceData.volume
            )
            
            priceUpdatesSubject.send(update)
        }
    }
}
