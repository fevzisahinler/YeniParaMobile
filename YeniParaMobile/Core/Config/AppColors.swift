import SwiftUI

enum AppColors {
    static let primary = Color(red: 143/255, green: 217/255, blue: 83/255)
    static let secondary = Color(red: 111/255, green: 170/255, blue: 12/255)
    static let background = Color(red: 28/255, green: 29/255, blue: 36/255)
    static let error = Color(red: 218/255, green: 60/255, blue: 46/255)
    
    static let cardBackground = Color.white.opacity(0.05)
    static let cardBorder = Color.white.opacity(0.1)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.5)
    
    // Gradients
    static let primaryGradient = LinearGradient(
        colors: [primary, secondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 28/255, green: 29/255, blue: 36/255),
            Color(red: 20/255, green: 21/255, blue: 28/255)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}
