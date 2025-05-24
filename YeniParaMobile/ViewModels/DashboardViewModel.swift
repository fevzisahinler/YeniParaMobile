import Foundation
import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var marketData: [String: String] = [:]
    @Published var featuredStocks: [Asset] = []
    @Published var news: [NewsItem] = []
    
    func loadDashboardData() {
        isLoading = true
        
        // Simulated data loading
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            marketData = [
                "sp500": "4,567.23",
                "nasdaq": "14,432.12",
                "dow": "34,876.45",
                "vix": "18.45"
            ]
            
            featuredStocks = [
                Asset(symbol: "AAPL", companyName: "Apple Inc.", price: 175.23, change: 4.12, changePercent: 2.45, volume: "45.2M", marketCap: "2.8T", high24h: 178.45, low24h: 172.10),
                Asset(symbol: "TSLA", companyName: "Tesla Inc.", price: 245.67, change: -3.08, changePercent: -1.23, volume: "32.1M", marketCap: "780B", high24h: 250.12, low24h: 242.50),
                Asset(symbol: "MSFT", companyName: "Microsoft Corp.", price: 348.91, change: 10.55, changePercent: 3.12, volume: "28.7M", marketCap: "2.6T", high24h: 352.30, low24h: 345.20)
            ]
            
            news = [
                NewsItem(title: "Fed Faiz Kararı Açıklandı", summary: "Federal Reserve faiz oranlarını sabit tutma kararı aldı", time: "2 saat önce"),
                NewsItem(title: "Apple'dan Yeni iPhone Açıklaması", summary: "Apple'ın yeni ürün lansmanı hisse fiyatlarını etkiledi", time: "4 saat önce")
            ]
            
            isLoading = false
        }
    }
}

struct NewsItem: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let time: String
}