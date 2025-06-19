import SwiftUI

enum AppConfig {
    #if DEBUG
    static let baseURL = "http://192.168.1.210:4000"
    #else
    static let baseURL = "https://api.yenipara.com"
    #endif
    
    static let googleClientID = "843475939935-6jrkdngl8v0j11vf39ansvjkc7n0qksq.apps.googleusercontent.com"
    
    enum Keychain {
        static let service = "YeniParaApp"
        static let accessTokenKey = "access_token"
        static let refreshTokenKey = "refresh_token"
    }
    
    enum API {
        static let requestTimeout: TimeInterval = 30
        static let resourceTimeout: TimeInterval = 60
        static let maxRetries = 3
    }
    
    enum Token {
        static let accessTokenExpiry: TimeInterval = 15 * 60 // 15 dakika
        static let refreshTokenExpiry: TimeInterval = 7 * 24 * 60 * 60 // 7 gün
    }
}
