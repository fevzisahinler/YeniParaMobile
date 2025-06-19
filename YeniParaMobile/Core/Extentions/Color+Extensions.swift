import SwiftUI

// MARK: - Color Extensions
extension Color {
    // MARK: - Hex Initialization
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // MARK: - Hex String
    var hexString: String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb: Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return String(format: "#%06x", rgb)
    }
    
    // MARK: - Brightness Adjustment
    func adjustBrightness(by amount: Double) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        let newBrightness = max(0, min(1, brightness + CGFloat(amount)))
        
        return Color(UIColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha))
    }
    
    // MARK: - Luminance
    var luminance: Double {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: nil)
        
        // Calculate relative luminance
        return 0.299 * Double(red) + 0.587 * Double(green) + 0.114 * Double(blue)
    }
    
    // MARK: - Contrast Color
    var contrastColor: Color {
        return luminance > 0.5 ? .black : .white
    }
    
    // MARK: - Random Color
    static var random: Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}

// MARK: - Gradient Extensions
extension LinearGradient {
    // MARK: - Predefined Gradients
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 28/255, green: 29/255, blue: 36/255),
                Color(red: 20/255, green: 21/255, blue: 28/255)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    static var successGradient: LinearGradient {
        LinearGradient(
            colors: [
                AppColors.primary,
                AppColors.primary.adjustBrightness(by: -0.2)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    static var errorGradient: LinearGradient {
        LinearGradient(
            colors: [
                AppColors.error,
                AppColors.error.adjustBrightness(by: -0.2)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Color Scheme Extensions
extension ColorScheme {
    var isDark: Bool {
        self == .dark
    }
    
    var isLight: Bool {
        self == .light
    }
}

// MARK: - UIColor Bridge
extension UIColor {
    var color: Color {
        Color(self)
    }
}

extension Color {
    var uiColor: UIColor {
        UIColor(self)
    }
}
