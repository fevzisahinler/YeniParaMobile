import Foundation
import SwiftUI

struct Asset: Identifiable, Codable {
    var id = UUID()
    let symbol: String
    let companyName: String
    let price: Double
    let change: Double
    let changePercent: Double
    let volume: String
    let marketCap: String
    let high24h: Double
    let low24h: Double
    
    var isPositiveChange: Bool { changePercent >= 0 }
    var changeColor: Color {
        isPositiveChange ? AppColors.primary : AppColors.error
    }
    
    var formattedPrice: String {
        "$\(String(format: "%.2f", price))"
    }
    
    var formattedChange: String {
        "\(isPositiveChange ? "+" : "")$\(String(format: "%.2f", change))"
    }
    
    var formattedChangePercent: String {
        "\(isPositiveChange ? "+" : "")\(String(format: "%.2f", changePercent))%"
    }
}