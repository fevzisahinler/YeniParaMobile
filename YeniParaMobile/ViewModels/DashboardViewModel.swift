import Foundation
import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {
    private var refreshTimer: Timer?
    @Published var isLoading = false
    @Published var marketData: [String: String] = [:]
    @Published var featuredStocks: [Asset] = []
    
    // Macro data
    @Published var macroSummary: MacroSummary?
    @Published var isMacroLoading = false
    @Published var macroError: String?
    
    // Stock data
    @Published var topGainers: [UISymbol] = []
    @Published var topLosers: [UISymbol] = []
    @Published var mostActive: [UISymbol] = []
    @Published var allStocks: [UISymbol] = []
    @Published var marketInfo: MarketInfo?
    
    // News data
    @Published var newsItems: [NewsItem] = []
    @Published var isNewsLoading = false
    @Published var newsError: String?
    @Published var currentNewsPage = 1
    @Published var totalNewsPages = 1
    @Published var hasMoreNews = true
    
    func loadDashboardData() {
        isLoading = true
        
        // Load macro data
        Task {
            await loadMacroData()
        }
        
        // Load stock data
        Task {
            await loadStockData()
        }
        
        // Load news data
        Task {
            await loadNews()
        }
        
        // Start auto refresh
        startAutoRefresh()
    }
    
    private func startAutoRefresh() {
        // Cancel existing timer if any
        refreshTimer?.invalidate()
        
        // Debug logging removed for production
        
        // Refresh every 60 seconds for price updates
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                await self.loadStockDataSilently()
            }
        }
    }
    
    private func loadStockDataSilently() async {
        // Same as loadStockData but without loading indicator
        do {
            // Get SP100 data with prices
            let sp100Response = try await APIService.shared.getSP100Symbols()
            
            if sp100Response.success {
                // Debug logging removed for production
                
                // Store market info
                self.marketInfo = sp100Response.data.market
                
                // Convert SP100 data to UISymbol
                self.allStocks = sp100Response.data.symbols.map { sp100Symbol in
                    var uiSymbol = UISymbol(
                        code: sp100Symbol.code,
                        name: sp100Symbol.name,
                        exchange: "NASDAQ",
                        logoPath: sp100Symbol.logoPath
                    )
                    
                    // Set real price data
                    uiSymbol.price = sp100Symbol.latestPrice
                    uiSymbol.change = sp100Symbol.latestPrice - sp100Symbol.prevClose
                    uiSymbol.changePercent = sp100Symbol.changePercent
                    uiSymbol.volume = sp100Symbol.volume
                    uiSymbol.high = sp100Symbol.dayHigh
                    uiSymbol.low = sp100Symbol.dayLow
                    uiSymbol.open = sp100Symbol.dayOpen
                    uiSymbol.previousClose = sp100Symbol.prevClose
                    
                    return uiSymbol
                }
                
                // Calculate top movers
                updateTopMovers()
            }
        } catch {
            // Debug logging removed for production
        }
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    func loadStockData() async {
        do {
            // Get SP100 data with prices
            let sp100Response = try await APIService.shared.getSP100Symbols()
            
            if sp100Response.success {
                // Store market info
                self.marketInfo = sp100Response.data.market
                
                // Convert SP100 data to UISymbol - using latestPrice directly from SP100
                self.allStocks = sp100Response.data.symbols.map { sp100Symbol in
                    var uiSymbol = UISymbol(
                        code: sp100Symbol.code,
                        name: sp100Symbol.name,
                        exchange: "NASDAQ",
                        logoPath: sp100Symbol.logoPath
                    )
                    
                    // Use latestPrice from SP100 API response
                    uiSymbol.price = sp100Symbol.latestPrice
                    uiSymbol.change = sp100Symbol.latestPrice - sp100Symbol.prevClose
                    uiSymbol.changePercent = sp100Symbol.changePercent
                    uiSymbol.volume = sp100Symbol.volume
                    uiSymbol.high = sp100Symbol.dayHigh
                    uiSymbol.low = sp100Symbol.dayLow
                    uiSymbol.open = sp100Symbol.dayOpen
                    uiSymbol.previousClose = sp100Symbol.prevClose
                    
                    // Debug logging removed for production
                    
                    return uiSymbol
                }
                
                // Calculate top movers
                updateTopMovers()
            }
        } catch {
            print("Error loading stock data: \(error)")
        }
        
        isLoading = false
    }
    
    private func updateTopMovers() {
        let activeStocks = allStocks.filter { $0.price > 0 }
        
        // Top gainers
        topGainers = Array(activeStocks
            .filter { $0.changePercent > 0 }
            .sorted { $0.changePercent > $1.changePercent }
            .prefix(4))
        
        // Top losers  
        topLosers = Array(activeStocks
            .filter { $0.changePercent < 0 }
            .sorted { $0.changePercent < $1.changePercent }
            .prefix(4))
        
        // Most active (by volume)
        mostActive = Array(activeStocks
            .sorted { $0.volume > $1.volume }
            .prefix(4))
    }
    
    func loadMacroData() async {
        isMacroLoading = true
        macroError = nil
        
        do {
            let summary = try await MacroService.shared.getMacroSummary()
            self.macroSummary = summary
        } catch {
            self.macroError = "Makroekonomik veriler yüklenemedi"
            print("Error loading macro data: \(error)")
        }
        
        isMacroLoading = false
    }
    
    func loadNews() async {
        isNewsLoading = true
        newsError = nil
        
        do {
            let response = try await NewsService.shared.getNews(page: currentNewsPage, limit: 10)
            
            if currentNewsPage == 1 {
                self.newsItems = response.data
            } else {
                self.newsItems.append(contentsOf: response.data)
            }
            
            self.totalNewsPages = response.pagination.totalPages
            self.hasMoreNews = response.pagination.currentPage < response.pagination.totalPages
        } catch {
            self.newsError = "Haberler yüklenemedi"
            print("Error loading news: \(error)")
        }
        
        isNewsLoading = false
    }
    
    func loadMoreNews() async {
        guard !isNewsLoading && hasMoreNews else { return }
        
        currentNewsPage += 1
        await loadNews()
    }
}