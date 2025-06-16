import Foundation
import SwiftUI

// MARK: - View Model
@MainActor
class HomeViewModel: ObservableObject {
    @Published var stocks: [UISymbol] = []
    @Published var filteredStocks: [UISymbol] = []
    @Published var topGainers: [UISymbol] = []
    @Published var topLosers: [UISymbol] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var searchText = "" {
        didSet {
            filterStocks()
        }
    }
    @Published var selectedFilter: FilterType = .all {
        didSet {
            filterStocks()
        }
    }
    
    private var favoriteStocks: Set<String> = []
    private var refreshTimer: Timer?
    
    init() {
        loadFavorites()
        startAutoRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    func loadData() async {
        isLoading = true
        showError = false
        errorMessage = ""
        
        do {
            // Use the APIService to get symbols with authentication
            let response = try await APIService.shared.getSymbols(page: 1, limit: 1000, sort: "code", order: "asc")
            
            if response.success {
                self.stocks = response.data.map { UISymbol(from: $0) }
                
                // Add mock price data for demonstration
                addMockPriceData()
                updateTopMovers()
                filterStocks()
            } else {
                throw APIError.serverError(0)
            }
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        await loadData()
    }
    
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task { @MainActor in
                // Only refresh mock prices, not full data
                self.addMockPriceData()
                self.updateTopMovers()
                self.filterStocks()
            }
        }
    }
    
    private func addMockPriceData() {
        for i in 0..<stocks.count {
            let basePrice = Double.random(in: 50...500)
            let change = Double.random(in: -20...20)
            let changePercent = (change / basePrice) * 100
            
            stocks[i].price = basePrice
            stocks[i].change = change
            stocks[i].changePercent = changePercent
            stocks[i].volume = Int64.random(in: 100_000...50_000_000)
            stocks[i].high = basePrice + Double.random(in: 0...10)
            stocks[i].low = basePrice - Double.random(in: 0...10)
            stocks[i].open = basePrice + Double.random(in: -5...5)
            stocks[i].previousClose = basePrice - change
        }
    }
    
    private func filterStocks() {
        var filtered = stocks
        
        if !searchText.isEmpty {
            filtered = filtered.filter { stock in
                stock.code.localizedCaseInsensitiveContains(searchText) ||
                stock.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        switch selectedFilter {
        case .all:
            break
        case .popular:
            // Popular stocks: High volume ones
            filtered = filtered.sorted { $0.volume > $1.volume }.prefix(50).map { $0 }
        case .gainers:
            filtered = filtered.filter { $0.changePercent > 0 }.sorted { $0.changePercent > $1.changePercent }
        case .favorites:
            filtered = filtered.filter { favoriteStocks.contains($0.code) }
        }
        
        filteredStocks = Array(filtered)
    }
    
    private func updateTopMovers() {
        let activeStocks = stocks.filter { $0.price > 0 }
        topGainers = Array(activeStocks.filter { $0.changePercent > 0 }
                                      .sorted { $0.changePercent > $1.changePercent }
                                      .prefix(5))
        topLosers = Array(activeStocks.filter { $0.changePercent < 0 }
                                     .sorted { $0.changePercent < $1.changePercent }
                                     .prefix(5))
    }
    
    private func loadFavorites() {
        if let saved = UserDefaults.standard.stringArray(forKey: "favoriteStocks") {
            favoriteStocks = Set(saved)
        }
    }
    
    private func handleError(_ error: Error) {
        if let apiError = error as? APIError {
            switch apiError {
            case .invalidURL:
                errorMessage = "Geçersiz URL adresi"
            case .invalidResponse:
                errorMessage = "Sunucu yanıtı geçersiz"
            case .serverError(let code):
                errorMessage = "Sunucu hatası (Kod: \(code))"
            case .unauthorized:
                errorMessage = "Oturum süreniz dolmuş. Lütfen tekrar giriş yapın."
            case .networkError:
                errorMessage = "İnternet bağlantısı yok"
            case .serverErrorWithMessage(_, let message):
                errorMessage = message
            case .decodingError:
                errorMessage = "Veri işleme hatası"
            }
        } else if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                errorMessage = "İnternet bağlantısı yok"
            case .timedOut:
                errorMessage = "Bağlantı zaman aşımına uğradı"
            default:
                errorMessage = "Ağ bağlantısı hatası"
            }
        } else {
            errorMessage = "Veri yüklenirken hata oluştu"
        }
        showError = true
    }
}
