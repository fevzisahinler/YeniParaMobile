import SwiftUI

// MARK: - Enhanced UISymbol Model
struct UISymbol {
    let code: String
    let name: String
    let exchange: String
    let logoPath: String
    var price: Double = 0
    var change: Double = 0
    var changePercent: Double = 0
    var volume: Int64 = 0
    var high: Double = 0
    var low: Double = 0
    var open: Double = 0
    var previousClose: Double = 0
    
    init(from apiSymbol: HomeAPISymbol) {
        self.code = apiSymbol.code
        self.name = apiSymbol.name
        self.exchange = apiSymbol.exchange
        self.logoPath = apiSymbol.logoPath
    }
    
    init(code: String, name: String, exchange: String, logoPath: String) {
        self.code = code
        self.name = name
        self.exchange = exchange
        self.logoPath = logoPath
    }
    
    var isPositive: Bool { changePercent >= 0 }
    
    var changeColor: Color {
        isPositive ? AppColors.primary : AppColors.error
    }
    
    var formattedPrice: String {
        if price == 0 { return "N/A" }
        return "$\(String(format: "%.2f", price))"
    }
    
    var formattedChange: String {
        if change == 0 { return "0.00" }
        return "\(isPositive ? "+" : "")$\(String(format: "%.2f", abs(change)))"
    }
    
    var formattedChangePercent: String {
        if changePercent == 0 { return "0.00%" }
        return "\(isPositive ? "+" : "")\(String(format: "%.2f", changePercent))%"
    }
    
    var formattedVolume: String {
        if volume == 0 { return "N/A" }
        if volume >= 1_000_000 {
            return String(format: "%.1fM", Double(volume) / 1_000_000)
        } else if volume >= 1_000 {
            return String(format: "%.0fK", Double(volume) / 1_000)
        } else {
            return "\(volume)"
        }
    }
    
    var dayRange: String {
        if low == 0 || high == 0 { return "N/A" }
        return "$\(String(format: "%.2f", low)) - $\(String(format: "%.2f", high))"
    }
}

// MARK: - API Models
struct HomeAPISymbol: Codable {
    let code: String
    let name: String
    let exchange: String
    let logoPath: String
    
    enum CodingKeys: String, CodingKey {
        case code, name, exchange
        case logoPath = "logo_path"
    }
}

// MARK: - API Response Models
struct HomeSymbolsAPIResponse: Codable {
    let success: Bool
    let data: [HomeAPISymbol]
    let pagination: HomePaginationInfo
    let meta: HomeMetaInfo
}

struct HomePaginationInfo: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let pages: Int
}

struct HomeMetaInfo: Codable {
    let timestamp: Int64
}
