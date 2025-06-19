import Foundation
import SwiftUI
import Combine

@MainActor
final class SymbolDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var symbol: String = ""
    @Published var fundamental: FundamentalData?
    @Published var candles: [CandleData] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var selectedTimeframe: Timeframe = .oneDay
    @Published var isInWatchlist = false
    
    // MARK: - Private Properties
    private let marketService: MarketServiceProtocol
    private let favoritesRepository: FavoritesRepositoryProtocol
    private let apiClient: APIClient
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Timeframe Enum
    enum Timeframe: String, CaseIterable {
        case oneDay = "1D"
        case oneWeek = "1W"
        case oneMonth = "1M"
        case threeMonths = "3M"
        case oneYear = "1Y"
        case all = "ALL"
        
        var apiValue: String {
            switch self {
            case .oneDay: return "1D"
            case .oneWeek: return "1W"
            case .oneMonth: return "1M"
            case .threeMonths: return "3M"
            case .oneYear: return "1Y"
            case .all: return "ALL"
            }
        }
    }
    
    // MARK: - Initialization
    init(marketService: MarketServiceProtocol = ServiceLocator.marketService,
         favoritesRepository: FavoritesRepositoryProtocol = ServiceLocator.favoritesRepository,
         apiClient: APIClient = ServiceLocator.apiClient) {
        self.marketService = marketService
        self.favoritesRepository = favoritesRepository
        self.apiClient = apiClient
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        favoritesRepository.favoritesPublisher
            .map { [weak self] favorites in
                guard let symbol = self?.symbol else { return false }
                return favorites.contains(symbol)
            }
            .assign(to: &$isInWatchlist)
    }
    
    // MARK: - Public Methods
    func loadData(for symbol: String) async {
        self.symbol = symbol
        isLoading = true
        showError = false
        
        async let fundamentalTask = loadFundamental()
        async let candlesTask = loadCandles()
        
        let _ = await (fundamentalTask, candlesTask)
        
        isLoading = false
    }
    
    func toggleWatchlist() {
        if isInWatchlist {
            favoritesRepository.removeFavorite(symbol)
        } else {
            favoritesRepository.addFavorite(symbol)
        }
    }
    
    func changeTimeframe(_ timeframe: Timeframe) {
        selectedTimeframe = timeframe
        Task {
            await loadCandles()
        }
    }
    
    func share() {
        // Implement share functionality
    }
    
    // MARK: - Private Methods
    private func loadFundamental() async {
        do {
            let response: FundamentalResponse = try await apiClient.request(
                MarketEndpoint.getFundamentalData(symbol: symbol)
            )
            
            if response.success {
                self.fundamental = response.data
            }
        } catch {
            handleError(error)
        }
    }
    
    private func loadCandles() async {
        do {
            let response: CandleResponse = try await apiClient.request(
                MarketEndpoint.getCandleData(
                    symbol: symbol,
                    timeframe: selectedTimeframe.apiValue,
                    from: nil,
                    to: nil
                )
            )
            
            self.candles = response.candles
        } catch {
            handleError(error)
        }
    }
    
    private func handleError(_ error: Error) {
        if let apiError = error as? APIError {
            errorMessage = apiError.errorDescription ?? "Bir hata oluştu"
        } else {
            errorMessage = error.localizedDescription
        }
        showError = true
    }
}
