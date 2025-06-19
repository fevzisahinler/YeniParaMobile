import Foundation
import SwiftUI
import Combine

// MARK: - Refactored Home View Model
@MainActor
final class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var stocks: [UISymbol] = []
    @Published var filteredStocks: [UISymbol] = []
    @Published var topGainers: [UISymbol] = []
    @Published var topLosers: [UISymbol] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var searchText = ""
    @Published var selectedFilter: FilterType = .all
    
    // MARK: - Private Properties
    private let apiClient: APIClient
    private let marketService: MarketServiceProtocol
    private let quizService: QuizServiceProtocol
    private let favoritesRepository: FavoritesRepositoryProtocol
    private let priceUpdateService = PriceUpdateService.shared
    
    private var cancellables = Set<AnyCancellable>()
    private var symbolsCache: [Symbol] = []
    private var investorProfile: InvestorProfile?
    
    // MARK: - Computed Properties
    var favoriteStocks: Set<String> {
        Set(favoritesRepository.getFavorites())
    }
    
    // MARK: - Initialization
    init(apiClient: APIClient = .shared,
         marketService: MarketServiceProtocol = MarketService.shared,
         quizService: QuizServiceProtocol = QuizService.shared,
         favoritesRepository: FavoritesRepositoryProtocol = FavoritesRepository.shared) {
        self.apiClient = apiClient
        self.marketService = marketService
        self.quizService = quizService
        self.favoritesRepository = favoritesRepository
        
        setupBindings()
        loadUserProfile()
    }
    
    deinit {
        priceUpdateService.stopUpdates()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Search text changes
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        // Filter changes
        $selectedFilter
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        // Price updates
        priceUpdateService.priceUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handlePriceUpdate(update)
            }
            .store(in: &cancellables)
        
        // Quiz profile updates
        quizService.quizStatusPublisher
            .receive(on: DispatchQueue.main)
            .compactMap { $0?.investorProfile }
            .sink { [weak self] profile in
                self?.investorProfile = profile
            }
            .store(in: &cancellables)
        
        // Favorites updates
        favoritesRepository.favoritesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                if self?.selectedFilter == .favorites {
                    self?.applyFilters()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func loadData() async {
        isLoading = true
        showError = false
        errorMessage = ""
        
        do {
            // Use MarketService instead of direct API call
            let symbols = try await marketService.getSymbols(
                page: 1,
                limit: 1000,
                sort: "code",
                order: "asc"
            )
            
            symbolsCache = symbols
            stocks = symbols.map { UISymbol(from: mapToHomeAPISymbol($0)) }
            
            // Start price updates
            priceUpdateService.startMockUpdates(for: symbols)
            
            // Update UI
            updateTopMovers()
            applyFilters()
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        await loadData()
    }
    
    func toggleFavorite(_ stockCode: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if favoriteStocks.contains(stockCode) {
                favoritesRepository.removeFavorite(stockCode)
            } else {
                favoritesRepository.addFavorite(stockCode)
            }
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    func calculateMatchScore(for stock: UISymbol) -> Int {
        return quizService.calculateMatchScore(
            for: stock.code,
            profile: investorProfile
        )
    }
    
    // MARK: - Private Methods
    private func loadUserProfile() {
        Task {
            do {
                let status = try await quizService.getQuizStatus()
                investorProfile = status.investorProfile
            } catch {
                // Silent fail - not critical for home view
                print("Failed to load user profile: \(error)")
            }
        }
    }
    
    private func applyFilters() {
        var filtered = stocks
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { stock in
                stock.code.localizedCaseInsensitiveContains(searchText) ||
                stock.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Category filter
        switch selectedFilter {
        case .all:
            break
            
        case .popular:
            // Popular stocks: High volume or frequently traded
            filtered = Array(filtered.sorted { $0.volume > $1.volume }.prefix(50))
            
        case .favorites:
            filtered = filtered.filter { favoriteStocks.contains($0.code) }
            
        case .recommended:
            // Sort by match score
            filtered = filtered.map { stock in
                var mutableStock = stock
                // Store match score for sorting
                return mutableStock
            }.sorted {
                calculateMatchScore(for: $0) > calculateMatchScore(for: $1)
            }
            filtered = Array(filtered.prefix(20))
        }
        
        // Update filtered list with animation
        withAnimation(.easeInOut(duration: 0.2)) {
            filteredStocks = filtered
        }
    }
    
    private func updateTopMovers() {
        let sortedByChange = stocks.sorted { $0.changePercent > $1.changePercent }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            topGainers = Array(sortedByChange.filter { $0.changePercent > 0 }.prefix(10))
            topLosers = Array(sortedByChange.filter { $0.changePercent < 0 }.suffix(10).reversed())
        }
    }
    
    private func handlePriceUpdate(_ update: PriceUpdateService.PriceUpdate) {
        guard let index = stocks.firstIndex(where: { $0.code == update.symbol }) else { return }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            stocks[index].price = update.price
            stocks[index].change = update.change
            stocks[index].changePercent = update.changePercent
            stocks[index].volume = update.volume
            
            // Update filtered stocks if needed
            if let filteredIndex = filteredStocks.firstIndex(where: { $0.code == update.symbol }) {
                filteredStocks[filteredIndex] = stocks[index]
            }
            
            // Update top movers if significant change
            if abs(update.changePercent) > 1.0 {
                updateTopMovers()
            }
        }
    }
    
    private func mapToHomeAPISymbol(_ symbol: Symbol) -> HomeAPISymbol {
        return HomeAPISymbol(
            code: symbol.code,
            name: symbol.name,
            exchange: symbol.exchange,
            logoPath: symbol.logoPath
        )
    }
    
    private func handleError(_ error: Error) {
        if let marketError = error as? MarketError {
            errorMessage = marketError.localizedDescription
        } else if let apiError = error as? APIError {
            errorMessage = apiError.localizedDescription
        } else {
            errorMessage = error.localizedDescription
        }
        
        showError = true
        
        // Log error for debugging
        print("❌ HomeViewModel Error: \(error)")
    }
    
    // MARK: - Public Methods (Additional)
    func getFilterCount(_ filter: FilterType) -> Int {
        switch filter {
        case .all:
            return stocks.count
        case .popular:
            return min(50, stocks.count)
        case .favorites:
            return favoriteStocks.count
        case .recommended:
            return min(20, stocks.count)
        }
    }
    
    var shouldShowTopMovers: Bool {
        selectedFilter == .all && searchText.isEmpty
    }
    
    // MARK: - Search Methods
    func searchStocks(_ query: String) async {
        guard !query.isEmpty else { return }
        
        isLoading = true
        
        do {
            let searchResults = try await marketService.searchSymbols(query: query)
            
            // Update stocks with search results
            let uiSymbols = searchResults.map { UISymbol(from: mapToHomeAPISymbol($0)) }
            
            withAnimation(.easeInOut(duration: 0.3)) {
                stocks = uiSymbols
                applyFilters()
            }
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
}

// MARK: - Filter Type
enum FilterType: String, CaseIterable {
    case all = "Tümü"
    case popular = "Popüler"
    case favorites = "Favoriler"
    case recommended = "Önerilen"
    
    var displayName: String { rawValue }
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .popular: return "flame"
        case .favorites: return "heart"
        case .recommended: return "star"
        }
    }
}
