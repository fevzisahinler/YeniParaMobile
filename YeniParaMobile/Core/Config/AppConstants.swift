import Foundation

enum AppConstants {
    enum Animation {
        static let duration: Double = 0.3
        static let springResponse: Double = 0.5
        static let springDamping: Double = 0.8
    }
    
    enum Layout {
        static let cornerRadius: CGFloat = 12
        static let cardPadding: CGFloat = 16
        static let screenPadding: CGFloat = 20
        static let spacing: CGFloat = 8
    }
    
    enum Size {
        static let iconSmall: CGFloat = 16
        static let iconMedium: CGFloat = 24
        static let iconLarge: CGFloat = 32
        static let buttonHeight: CGFloat = 52
    }
    
    // Convenience properties
    static let cornerRadius = Layout.cornerRadius
    static let cardPadding = Layout.cardPadding
    static let screenPadding = Layout.screenPadding
}
