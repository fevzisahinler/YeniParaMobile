import Foundation
import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var marketData: [String: String] = [:]
    @Published var featuredStocks: [Asset] = []
    @Published var news: [NewsItem] = []
    
    // Macro data
    @Published var macroSummary: MacroSummary?
    @Published var isMacroLoading = false
    @Published var macroError: String?
    
    // Stock data
    @Published var topGainers: [UISymbol] = []
    @Published var topLosers: [UISymbol] = []
    @Published var mostActive: [UISymbol] = []
    @Published var allStocks: [UISymbol] = []
    
    func loadDashboardData() {
        isLoading = true
        
        // Load macro data
        Task {
            await loadMacroData()
        }
        
        // Load stock data
        Task {
            await loadStockData()
        }
    }
    
    func loadStockData() async {
        do {
            // Get SP100 data with prices
            let sp100Response = try await APIService.shared.getSP100Symbols()
            
            if sp100Response.success {
                // Convert SP100 data to UISymbol
                self.allStocks = sp100Response.data.symbols.map { sp100Symbol in
                    var uiSymbol = UISymbol(
                        code: sp100Symbol.code,
                        name: sp100Symbol.name,
                        exchange: "NASDAQ",
                        logoPath: "/api/v1/logos/\(sp100Symbol.code).jpeg"
                    )
                    
                    // Set real price data
                    uiSymbol.price = sp100Symbol.latestPrice
                    uiSymbol.change = sp100Symbol.change
                    uiSymbol.changePercent = sp100Symbol.changePercent
                    uiSymbol.volume = sp100Symbol.volume
                    uiSymbol.high = sp100Symbol.dayHigh
                    uiSymbol.low = sp100Symbol.dayLow
                    uiSymbol.open = sp100Symbol.dayOpen
                    uiSymbol.previousClose = sp100Symbol.prevClose
                    
                    return uiSymbol
                }
                
                // Calculate top movers
                updateTopMovers()
            }
        } catch {
            print("Error loading stock data: \(error)")
        }
        
        isLoading = false
    }
    
    private func updateTopMovers() {
        let activeStocks = allStocks.filter { $0.price > 0 }
        
        // Top gainers
        topGainers = Array(activeStocks
            .filter { $0.changePercent > 0 }
            .sorted { $0.changePercent > $1.changePercent }
            .prefix(4))
        
        // Top losers  
        topLosers = Array(activeStocks
            .filter { $0.changePercent < 0 }
            .sorted { $0.changePercent < $1.changePercent }
            .prefix(4))
        
        // Most active (by volume)
        mostActive = Array(activeStocks
            .sorted { $0.volume > $1.volume }
            .prefix(4))
    }
    
    func loadMacroData() async {
        isMacroLoading = true
        macroError = nil
        
        do {
            let summary = try await MacroService.shared.getMacroSummary()
            self.macroSummary = summary
        } catch {
            self.macroError = "Makroekonomik veriler yüklenemedi"
            print("Error loading macro data: \(error)")
        }
        
        isMacroLoading = false
    }
}

struct NewsItem: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let time: String
}