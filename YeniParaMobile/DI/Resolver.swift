import Foundation

// MARK: - Service Locator
enum ServiceLocator {
    private static let container = AppContainer.shared
    
    // MARK: - Core Services
    static var apiClient: APIClient { container.apiClient }
    static var cacheManager: CacheManager { container.cacheManager }
    static var tokenManager: TokenManager { container.tokenManager }
    static var networkMonitor: NetworkMonitor { container.networkMonitor }
    
    // MARK: - Business Services
    static var authService: AuthServiceProtocol { container.authService }
    static var marketService: MarketServiceProtocol { container.marketService }
    static var quizService: QuizServiceProtocol { container.quizService }
    static var userService: UserServiceProtocol { container.userService }
    
    // MARK: - Repositories
    static var favoritesRepository: FavoritesRepositoryProtocol { container.favoritesRepository }
    static var userDefaultsRepository: UserDefaultsRepository { container.userDefaultsRepository }
    static var marketRepository: MarketRepositoryProtocol { container.marketRepository }
    static var quizRepository: QuizRepositoryProtocol { container.quizRepository }
    
    // MARK: - View Model Factory
    @MainActor
        static func makeAuthViewModel() -> AuthViewModel {
            container.makeAuthViewModel()
        }
        
        @MainActor
        static func makeHomeViewModel() -> HomeViewModel {
            container.makeHomeViewModel()
        }
        
        @MainActor
        static func makeDashboardViewModel() -> DashboardViewModel {
            container.makeDashboardViewModel()
        }
        
        @MainActor
        static func makeSymbolDetailViewModel() -> SymbolDetailViewModel {
            container.makeSymbolDetailViewModel()
        }
}
