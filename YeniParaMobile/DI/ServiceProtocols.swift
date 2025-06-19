import Foundation
import Combine

// MARK: - Base Service Protocol
protocol BaseServiceProtocol {
    var isLoading: CurrentValueSubject<Bool, Never> { get }
    var error: CurrentValueSubject<Error?, Never> { get }
}

// MARK: - User Service Protocol
protocol UserServiceProtocol: BaseServiceProtocol {
    var currentUserId: Int? { get }
    
    func getUserProfile(userId: Int) async throws -> UserProfile
    func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile
    func getUserSettings() async throws -> UserSettings
    func updateUserSettings(_ settings: UserSettings) async throws -> UserSettings
    func deleteAccount() async throws
}

// MARK: - Analytics Service Protocol
protocol AnalyticsServiceProtocol {
    func track(event: AnalyticsEvent)
    func setUserProperty(key: String, value: Any)
    func logScreen(name: String, parameters: [String: Any]?)
}

// MARK: - Notification Service Protocol
protocol NotificationServiceProtocol {
    func requestPermission() async -> Bool
    func registerForPushNotifications() async throws
    func handleNotification(_ notification: [String: Any])
    func setBadgeCount(_ count: Int)
    func scheduleLocalNotification(title: String, body: String, after: TimeInterval)
}

// MARK: - Network Monitor Protocol
protocol NetworkMonitorProtocol {
    var isConnected: CurrentValueSubject<Bool, Never> { get }
    var connectionType: CurrentValueSubject<NetworkConnectionType, Never> { get }
    
    func startMonitoring()
    func stopMonitoring()
}

// MARK: - Supporting Types
struct UserProfile: Codable {
    let id: Int
    let email: String
    let username: String
    let fullName: String
    let phoneNumber: String
    let profilePicture: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, email, username
        case fullName = "full_name"
        case phoneNumber = "phone_number"
        case profilePicture = "profile_picture"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct UserSettings: Codable {
    var enableNotifications: Bool
    var enableBiometricAuth: Bool
    var preferredLanguage: String
    var theme: AppTheme
    var enableHapticFeedback: Bool
    var autoRefreshInterval: TimeInterval
    var chartType: ChartType
    var showPercentageChange: Bool
    
    enum AppTheme: String, Codable {
        case light, dark, system
    }
    
    enum ChartType: String, Codable {
        case line, candle, area
    }
}

enum NetworkConnectionType {
    case wifi
    case cellular
    case ethernet
    case unknown
}

// MARK: - Analytics Event
struct AnalyticsEvent {
    let name: String
    let parameters: [String: Any]?
    
    // Predefined events
    static func screenView(_ screenName: String) -> AnalyticsEvent {
        return AnalyticsEvent(name: "screen_view", parameters: ["screen_name": screenName])
    }
    
    static func buttonTap(_ buttonName: String, screen: String) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "button_tap",
            parameters: ["button_name": buttonName, "screen": screen]
        )
    }
    
    static func stockViewed(_ symbol: String) -> AnalyticsEvent {
        return AnalyticsEvent(name: "stock_viewed", parameters: ["symbol": symbol])
    }
    
    static func favoriteToggled(_ symbol: String, isFavorite: Bool) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "favorite_toggled",
            parameters: ["symbol": symbol, "is_favorite": isFavorite]
        )
    }
    
    static func quizCompleted(profile: String, score: Int) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "quiz_completed",
            parameters: ["profile": profile, "score": score]
        )
    }
    
    static func error(_ error: String, screen: String) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "error_occurred",
            parameters: ["error": error, "screen": screen]
        )
    }
}
