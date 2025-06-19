import Foundation
import Combine

// MARK: - User Service Implementation
final class UserService: UserServiceProtocol {
    // MARK: - Properties
    static let shared = UserService()
    
    let isLoading = CurrentValueSubject<Bool, Never>(false)
    let error = CurrentValueSubject<Error?, Never>(nil)
    
    private let apiClient: APIClient
    private let cacheManager: CacheManager
    private let authService: AuthServiceProtocol
    
    var currentUserId: Int? {
        authService.currentUser.value?.id
    }
    
    // MARK: - Initialization
    init(apiClient: APIClient = .shared,
         cacheManager: CacheManager = .shared,
         authService: AuthServiceProtocol = AuthService.shared) {
        self.apiClient = apiClient
        self.cacheManager = cacheManager
        self.authService = authService
    }
    
    // MARK: - Public Methods
    func getUserProfile(userId: Int) async throws -> UserProfile {
        isLoading.send(true)
        defer { isLoading.send(false) }
        
        // Check cache first
        let cacheKey = "user_profile_\(userId)"
        if let cached: UserProfile = await cacheManager.get(key: cacheKey) {
            return cached
        }
        
        // Fetch from API
        let endpoint = UserEndpoint.getProfile(userId: userId)
        let response: UserProfileResponse = try await apiClient.request(endpoint)
        
        guard response.success, let profile = response.data else {
            throw UserError.profileNotFound
        }
        
        // Cache for 5 minutes
        await cacheManager.set(profile, key: cacheKey, expiry: 300)
        
        return profile
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile {
        isLoading.send(true)
        defer { isLoading.send(false) }
        
        let endpoint = UserEndpoint.updateProfile(profile)
        let response: UserProfileResponse = try await apiClient.request(endpoint)
        
        guard response.success, let updatedProfile = response.data else {
            throw UserError.updateFailed
        }
        
        // Update cache
        let cacheKey = "user_profile_\(profile.id)"
        await cacheManager.set(updatedProfile, key: cacheKey, expiry: 300)
        
        return updatedProfile
    }
    
    func getUserSettings() async throws -> UserSettings {
        isLoading.send(true)
        defer { isLoading.send(false) }
        
        // First check local storage
        if let localSettings = UserDefaultsRepository.shared.get(UserSettings.self, for: "user_settings") {
            return localSettings
        }
        
        // Fetch from API if not in local storage
        let endpoint = UserEndpoint.getSettings
        let response: UserSettingsResponse = try await apiClient.request(endpoint)
        
        guard response.success, let settings = response.data else {
            // Return default settings if API fails
            return UserSettings(
                enableNotifications: true,
                enableBiometricAuth: false,
                preferredLanguage: "tr",
                theme: .dark,
                enableHapticFeedback: true,
                autoRefreshInterval: 30,
                chartType: .line,
                showPercentageChange: true
            )
        }
        
        // Save to local storage
        UserDefaultsRepository.shared.set(settings, for: "user_settings")
        
        return settings
    }
    
    func updateUserSettings(_ settings: UserSettings) async throws -> UserSettings {
        isLoading.send(true)
        defer { isLoading.send(false) }
        
        // Save to local storage immediately
        UserDefaultsRepository.shared.set(settings, for: "user_settings")
        
        // Try to sync with server
        do {
            let endpoint = UserEndpoint.updateSettings(settings)
            let response: UserSettingsResponse = try await apiClient.request(endpoint)
            
            guard response.success, let updatedSettings = response.data else {
                throw UserError.updateFailed
            }
            
            // Update local storage with server response
            UserDefaultsRepository.shared.set(updatedSettings, for: "user_settings")
            
            return updatedSettings
        } catch {
            // If server update fails, still return local settings
            self.error.send(error)
            return settings
        }
    }
    
    func deleteAccount() async throws {
        isLoading.send(true)
        defer { isLoading.send(false) }
        
        let endpoint = UserEndpoint.deleteAccount
        let response: MessageResponse = try await apiClient.request(endpoint)
        
        guard response.success else {
            throw UserError.deleteFailed
        }
        
        // Clear all local data
        await clearAllUserData()
        
        // Logout
        try await authService.logout()
    }
    
    // MARK: - Private Methods
    private func clearAllUserData() async {
        // Clear cache
        await cacheManager.clearAll()
        
        // Clear user defaults
        UserDefaultsRepository.shared.remove(for: "user_settings")
        UserDefaultsRepository.shared.remove(for: "favoriteStocks")
        
        // Clear keychain
        await TokenManager.shared.clearTokens()
    }
}

// MARK: - User Endpoints
enum UserEndpoint: APIEndpoint {
    case getProfile(userId: Int)
    case updateProfile(UserProfile)
    case getSettings
    case updateSettings(UserSettings)
    case deleteAccount
    
    var path: String {
        switch self {
        case .getProfile(let userId):
            return "/api/v1/users/\(userId)"
        case .updateProfile:
            return "/api/v1/users/profile"
        case .getSettings:
            return "/api/v1/users/settings"
        case .updateSettings:
            return "/api/v1/users/settings"
        case .deleteAccount:
            return "/api/v1/users/account"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getProfile, .getSettings:
            return .GET
        case .updateProfile, .updateSettings:
            return .PUT
        case .deleteAccount:
            return .DELETE
        }
    }
    
    var body: Data? {
        switch self {
        case .updateProfile(let profile):
            return encodeBody(profile)
        case .updateSettings(let settings):
            return encodeBody(settings)
        default:
            return nil
        }
    }
}

// MARK: - Response Models
struct UserProfileResponse: Codable {
    let success: Bool
    let data: UserProfile?
    let error: String?
}

struct UserSettingsResponse: Codable {
    let success: Bool
    let data: UserSettings?
    let error: String?
}

// MARK: - User Errors
enum UserError: LocalizedError {
    case profileNotFound
    case updateFailed
    case deleteFailed
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .profileNotFound:
            return "Kullanıcı profili bulunamadı"
        case .updateFailed:
            return "Güncelleme başarısız"
        case .deleteFailed:
            return "Hesap silinirken hata oluştu"
        case .unauthorized:
            return "Yetkilendirme hatası"
        }
    }
}
