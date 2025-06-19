import Foundation
import Combine

// MARK: - Auth Service Protocol
protocol AuthServiceProtocol {
    var currentUser: CurrentValueSubject<User?, Never> { get }
    var isAuthenticated: CurrentValueSubject<Bool, Never> { get }
    
    func login(email: String, password: String) async throws -> User
    func register(_ request: RegisterRequest) async throws -> AuthResponse
    func verifyEmail(userId: Int, code: String) async throws -> MessageResponse
    func resendOTP(userId: Int) async throws -> MessageResponse
    func forgotPassword(email: String) async throws
    func resetPassword(email: String, code: String, newPassword: String) async throws
    func logout() async throws
    func refreshTokenIfNeeded() async -> Bool
    func getQuizStatus() async throws -> QuizStatusResponse
}

// MARK: - Auth Service Implementation
final class AuthService: AuthServiceProtocol {
    // MARK: - Properties
    static let shared = AuthService()
    
    let currentUser = CurrentValueSubject<User?, Never>(nil)
    let isAuthenticated = CurrentValueSubject<Bool, Never>(false)
    
    private let apiClient: APIClient
    private let tokenManager: TokenManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(apiClient: APIClient = .shared, tokenManager: TokenManager = .shared) {
        self.apiClient = apiClient
        self.tokenManager = tokenManager
        
        setupBindings()
        checkAuthStatus()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Update authentication status based on token availability
        tokenManager.$accessToken
            .map { $0 != nil }
            .sink { [weak self] isAuth in
                self?.isAuthenticated.send(isAuth)
            }
            .store(in: &cancellables)
    }
    
    private func checkAuthStatus() {
        Task {
            if tokenManager.hasValidToken {
                _ = await refreshTokenIfNeeded()
            }
        }
    }
    
    // MARK: - Public Methods
    func login(email: String, password: String) async throws -> User {
        let response: AuthResponse = try await apiClient.request(
            AuthEndpoint.login(email: email, password: password)
        )
        
        guard response.success, let data = response.data else {
            throw AuthError.loginFailed(response.error ?? "Login failed")
        }
        
        // Save tokens
        if let accessToken = data.accessToken,
           let refreshToken = data.refreshToken {
            await tokenManager.saveTokens(
                accessToken: accessToken,
                refreshToken: refreshToken
            )
        }
        
        // Update current user
        let user = data.user ?? User(
            id: data.userId,
            email: email,
            username: "",
            fullName: "",
            phoneNumber: "",
            isQuizCompleted: false,
            createdAt: ""
        )
        
        currentUser.send(user)
        
        return user
    }
    
    func register(_ request: RegisterRequest) async throws -> AuthResponse {
        let response: AuthResponse = try await apiClient.request(
            AuthEndpoint.register(request)
        )
        
        guard response.success else {
            throw AuthError.registrationFailed(response.error ?? "Registration failed")
        }
        
        return response
    }
    
    func verifyEmail(userId: Int, code: String) async throws -> MessageResponse {
        let response: MessageResponse = try await apiClient.request(
            AuthEndpoint.verifyEmail(userId: userId, code: code)
        )
        
        guard response.success else {
            throw AuthError.verificationFailed(response.message)
        }
        
        return response
    }
    
    func resendOTP(userId: Int) async throws -> MessageResponse {
        let response: MessageResponse = try await apiClient.request(
            AuthEndpoint.resendOTP(userId: userId)
        )
        
        guard response.success else {
            throw AuthError.otpResendFailed(response.message)
        }
        
        return response
    }
    
    func forgotPassword(email: String) async throws {
        let response: MessageResponse = try await apiClient.request(
            AuthEndpoint.forgotPassword(email: email)
        )
        
        guard response.success else {
            throw AuthError.forgotPasswordFailed(response.message)
        }
    }
    
    func resetPassword(email: String, code: String, newPassword: String) async throws {
        let response: MessageResponse = try await apiClient.request(
            AuthEndpoint.resetPassword(email: email, code: code, newPassword: newPassword)
        )
        
        guard response.success else {
            throw AuthError.resetPasswordFailed(response.message)
        }
    }
    
    func logout() async throws {
        // Call logout endpoint if needed
        // try await apiClient.request(AuthEndpoint.logout)
        
        // Clear tokens
        await tokenManager.clearTokens()
        
        // Clear user
        currentUser.send(nil)
        
        // Clear any cached data
        await CacheManager.shared.clearAll()
    }
    
    func refreshTokenIfNeeded() async -> Bool {
        guard let refreshToken = tokenManager.refreshToken else { return false }
        
        do {
            let response: AuthResponse = try await apiClient.request(
                AuthEndpoint.refreshToken(refreshToken: refreshToken)
            )
            
            guard response.success,
                  let data = response.data,
                  let newAccessToken = data.accessToken else {
                return false
            }
            
            // Save new token
            await tokenManager.saveTokens(
                accessToken: newAccessToken,
                refreshToken: refreshToken
            )
            
            return true
            
        } catch {
            // If refresh fails, logout
            try? await logout()
            return false
        }
    }
    
    func getQuizStatus() async throws -> QuizStatusResponse {
        return try await apiClient.request(QuizEndpoint.getStatus)
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case loginFailed(String)
    case registrationFailed(String)
    case verificationFailed(String)
    case otpResendFailed(String)
    case forgotPasswordFailed(String)
    case resetPasswordFailed(String)
    case userIdNotFound
    case tokenRefreshFailed
    
    var errorDescription: String? {
        switch self {
        case .loginFailed(let message):
            return message
        case .registrationFailed(let message):
            return message
        case .verificationFailed(let message):
            return message
        case .otpResendFailed(let message):
            return message
        case .forgotPasswordFailed(let message):
            return message
        case .resetPasswordFailed(let message):
            return message
        case .userIdNotFound:
            return "Kullanıcı ID'si bulunamadı"
        case .tokenRefreshFailed:
            return "Token yenileme başarısız"
        }
    }
}

// MARK: - Token Manager
final class TokenManager: ObservableObject {
    static let shared = TokenManager()
    
    @Published private(set) var accessToken: String?
    @Published private(set) var refreshToken: String?
    
    private let keychainHelper = KeychainHelper.shared
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    private let tokenExpiryKey = "token_expiry"
    private let keychainService = "YeniParaApp"
    
    private var tokenExpiryDate: Date?
    
    var hasValidToken: Bool {
        guard let _ = accessToken,
              let expiryDate = tokenExpiryDate else { return false }
        return Date() < expiryDate
    }
    
    init() {
        loadStoredTokens()
    }
    
    func saveTokens(accessToken: String, refreshToken: String) async {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        
        // Save to keychain
        if let accessData = accessToken.data(using: .utf8) {
            keychainHelper.save(accessData, service: keychainService, account: accessTokenKey)
        }
        
        if let refreshData = refreshToken.data(using: .utf8) {
            keychainHelper.save(refreshData, service: keychainService, account: refreshTokenKey)
        }
        
        // Set expiry (15 minutes)
        tokenExpiryDate = Date().addingTimeInterval(900)
        if let expiryData = try? JSONEncoder().encode(tokenExpiryDate) {
            keychainHelper.save(expiryData, service: keychainService, account: tokenExpiryKey)
        }
    }
    
    func clearTokens() async {
        accessToken = nil
        refreshToken = nil
        tokenExpiryDate = nil
        
        keychainHelper.delete(service: keychainService, account: accessTokenKey)
        keychainHelper.delete(service: keychainService, account: refreshTokenKey)
        keychainHelper.delete(service: keychainService, account: tokenExpiryKey)
    }
    
    private func loadStoredTokens() {
        // Load access token
        if let data = keychainHelper.read(service: keychainService, account: accessTokenKey),
           let token = String(data: data, encoding: .utf8) {
            self.accessToken = token
        }
        
        // Load refresh token
        if let data = keychainHelper.read(service: keychainService, account: refreshTokenKey),
           let token = String(data: data, encoding: .utf8) {
            self.refreshToken = token
        }
        
        // Load expiry date
        if let data = keychainHelper.read(service: keychainService, account: tokenExpiryKey),
           let date = try? JSONDecoder().decode(Date.self, from: data) {
            self.tokenExpiryDate = date
        }
    }
}

// MARK: - Extensions
extension TokenManager: AuthManagerProtocol {
    func refreshTokenIfNeeded() async -> Bool {
        return await AuthService.shared.refreshTokenIfNeeded()
    }
    
    func logout() async {
        try? await AuthService.shared.logout()
    }
}
