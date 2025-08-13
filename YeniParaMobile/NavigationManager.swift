import SwiftUI

class NavigationManager: ObservableObject {
    @Published var selectedStock: String? = nil
    @Published var showStockDetail = false
    @Published var selectedMacroType: MacroDataType? = nil
    @Published var showMacroDetail = false
    @Published var selectedNews: NewsItem? = nil
    @Published var showNewsDetail = false
    
    func navigateToStock(_ symbol: String) {
        print("DEBUG: NavigationManager - navigateToStock called with symbol: \(symbol)")
        selectedStock = symbol
        
        // Add a small delay to prevent animation issues on first tap
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showStockDetail = true
        }
        
        print("DEBUG: NavigationManager - showStockDetail: \(showStockDetail), selectedStock: \(String(describing: selectedStock))")
    }
    
    func dismissStockDetail() {
        showStockDetail = false
        selectedStock = nil
    }
    
    func navigateToMacroDetail(_ type: MacroDataType) {
        selectedMacroType = type
        showMacroDetail = true
    }
    
    func dismissMacroDetail() {
        showMacroDetail = false
        selectedMacroType = nil
    }
    
    func navigateToNewsDetail(_ news: NewsItem) {
        selectedNews = news
        showNewsDetail = true
    }
    
    func dismissNewsDetail() {
        showNewsDetail = false
        selectedNews = nil
    }
}