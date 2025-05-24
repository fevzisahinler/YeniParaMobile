import SwiftUI

struct AppColors {
    static let primary = Color(red: 143/255, green: 217/255, blue: 83/255)
    static let secondary = Color(red: 111/255, green: 170/255, blue: 12/255)
    static let background = Color(red: 28/255, green: 29/255, blue: 36/255)
    static let error = Color(red: 218/255, green: 60/255, blue: 46/255)
    
    static let cardBackground = Color.white.opacity(0.05)
    static let cardBorder = Color.white.opacity(0.1)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.5)
}

struct AppConfig {
    static let baseURL = "http://localhost:4000"
    static let googleClientID = "843475939935-6jrkdngl8v0j11vf39ansvjkc7n0qksq.apps.googleusercontent.com"
}

struct AppConstants {
    static let animationDuration: Double = 0.3
    static let cornerRadius: CGFloat = 12
    static let cardPadding: CGFloat = 16
    static let screenPadding: CGFloat = 20
}
