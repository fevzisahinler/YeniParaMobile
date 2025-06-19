import Foundation
import Combine

// MARK: - Favorites Repository Protocol
protocol FavoritesRepositoryProtocol {
    func getFavorites() -> [String]
    func addFavorite(_ symbol: String)
    func removeFavorite(_ symbol: String)
    func isFavorite(_ symbol: String) -> Bool
    func clearAll()
    
    var favoritesPublisher: AnyPublisher<Set<String>, Never> { get }
}

// MARK: - Favorites Repository Implementation
final class FavoritesRepository: FavoritesRepositoryProtocol, ObservableObject {
    // MARK: - Properties
    static let shared = FavoritesRepository()
    
    private let userDefaults: UserDefaults
    private let favoritesKey = "favoriteStocks"
    private let maxFavorites = 50
    
    @Published private var favorites: Set<String> = []
    
    var favoritesPublisher: AnyPublisher<Set<String>, Never> {
        $favorites.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadFavorites()
    }
    
    // MARK: - Public Methods
    func getFavorites() -> [String] {
        return Array(favorites)
    }
    
    func addFavorite(_ symbol: String) {
        guard !symbol.isEmpty else { return }
        
        // Check limit
        if favorites.count >= maxFavorites {
            // Remove oldest favorite if at limit
            if let oldest = getFavorites().first {
                favorites.remove(oldest)
            }
        }
        
        favorites.insert(symbol)
        saveFavorites()
        
        // Track analytics
        FavoritesAnalytics.shared.trackFavoriteAdded(symbol)
    }
    
    func removeFavorite(_ symbol: String) {
        favorites.remove(symbol)
        saveFavorites()
        
        // Track analytics
        FavoritesAnalytics.shared.trackFavoriteRemoved(symbol)
    }
    
    func isFavorite(_ symbol: String) -> Bool {
        return favorites.contains(symbol)
    }
    
    func clearAll() {
        let count = favorites.count
        favorites.removeAll()
        saveFavorites()
        
        // Track analytics
        FavoritesAnalytics.shared.trackAllFavoritesCleared(count: count)
    }
    
    // MARK: - Private Methods
    private func loadFavorites() {
        if let saved = userDefaults.stringArray(forKey: favoritesKey) {
            favorites = Set(saved)
        }
    }
    
    private func saveFavorites() {
        userDefaults.set(Array(favorites), forKey: favoritesKey)
    }
}

// MARK: - Favorites Analytics
final class FavoritesAnalytics {
    static let shared = FavoritesAnalytics()
    
    private let userDefaults = UserDefaults.standard
    private let analyticsKey = "favoritesAnalytics"
    
    private init() {}
    
    func trackFavoriteAdded(_ symbol: String) {
        var analytics = getAnalytics()
        analytics.totalAdded += 1
        analytics.lastAddedSymbol = symbol
        analytics.lastAddedDate = Date()
        
        // Track most favorited
        analytics.symbolCounts[symbol, default: 0] += 1
        
        saveAnalytics(analytics)
        
        print("📊 Favorite added: \(symbol)")
    }
    
    func trackFavoriteRemoved(_ symbol: String) {
        var analytics = getAnalytics()
        analytics.totalRemoved += 1
        analytics.lastRemovedSymbol = symbol
        analytics.lastRemovedDate = Date()
        
        saveAnalytics(analytics)
        
        print("📊 Favorite removed: \(symbol)")
    }
    
    func trackAllFavoritesCleared(count: Int) {
        var analytics = getAnalytics()
        analytics.totalCleared += count
        analytics.lastClearedDate = Date()
        
        saveAnalytics(analytics)
        
        print("📊 All favorites cleared: \(count) items")
    }
    
    func getMostFavoritedSymbols(limit: Int = 10) -> [(symbol: String, count: Int)] {
        let analytics = getAnalytics()
        return analytics.symbolCounts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { ($0.key, $0.value) }
    }
    
    private func getAnalytics() -> FavoritesAnalyticsData {
        guard let data = userDefaults.data(forKey: analyticsKey),
              let analytics = try? JSONDecoder().decode(FavoritesAnalyticsData.self, from: data) else {
            return FavoritesAnalyticsData()
        }
        return analytics
    }
    
    private func saveAnalytics(_ analytics: FavoritesAnalyticsData) {
        if let data = try? JSONEncoder().encode(analytics) {
            userDefaults.set(data, forKey: analyticsKey)
        }
    }
}

// MARK: - Analytics Data Model
private struct FavoritesAnalyticsData: Codable {
    var totalAdded: Int = 0
    var totalRemoved: Int = 0
    var totalCleared: Int = 0
    var lastAddedSymbol: String?
    var lastRemovedSymbol: String?
    var lastAddedDate: Date?
    var lastRemovedDate: Date?
    var lastClearedDate: Date?
    var symbolCounts: [String: Int] = [:]
}
