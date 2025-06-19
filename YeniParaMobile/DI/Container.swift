import Foundation

// MARK: - App Container
final class AppContainer {
    static let shared = AppContainer()
    
    private init() {
        Task { @MainActor in
            setupDependencies()
        }
    }
    
    // MARK: - Core Services
    private(set) lazy var apiClient = APIClient.shared
    private(set) lazy var cacheManager = CacheManager.shared
    private(set) lazy var tokenManager = TokenManager.shared
    private(set) lazy var networkMonitor = NetworkMonitor.shared
    
    // MARK: - Services
    private(set) lazy var authService: AuthServiceProtocol = AuthService.shared
    private(set) lazy var marketService: MarketServiceProtocol = MarketService.shared
    private(set) lazy var quizService: QuizServiceProtocol = QuizService.shared
    private(set) lazy var userService: UserServiceProtocol = UserService.shared
    
    // MARK: - Repositories
    private(set) lazy var favoritesRepository: FavoritesRepositoryProtocol = FavoritesRepository.shared
    private(set) lazy var userDefaultsRepository = UserDefaultsRepository.shared
    private(set) lazy var marketRepository: MarketRepositoryProtocol = MarketRepository.shared
    private(set) lazy var quizRepository: QuizRepositoryProtocol = QuizRepository.shared
    
    // MARK: - Setup
    @MainActor
    private func setupDependencies() {
        // Set up auth manager for API client
        apiClient.setAuthManager(tokenManager)
    }
    
    // MARK: - View Model Factory
    @MainActor
    func makeAuthViewModel() -> AuthViewModel {
        return AuthViewModel(
            authService: authService,
            quizService: quizService
        )
    }
    
    @MainActor
    func makeHomeViewModel() -> HomeViewModel {
        return HomeViewModel(
            apiClient: apiClient,
            marketService: marketService,
            quizService: quizService,
            favoritesRepository: favoritesRepository
        )
    }
    
    @MainActor
    func makeDashboardViewModel() -> DashboardViewModel {
        return DashboardViewModel()
    }
    
    @MainActor
    func makeSymbolDetailViewModel() -> SymbolDetailViewModel {
        return SymbolDetailViewModel(
            marketService: marketService,
            favoritesRepository: favoritesRepository,
            apiClient: apiClient
        )
    }
}
