import SwiftUI

class NavigationManager: ObservableObject {
    @Published var selectedStock: String? = nil
    @Published var showStockDetail = false
    @Published var selectedMacroType: MacroDataType? = nil
    @Published var showMacroDetail = false
    @Published var selectedNews: NewsItem? = nil
    @Published var showNewsDetail = false
    
    func navigateToStock(_ symbol: String) {
        selectedStock = symbol
        showStockDetail = true
    }
    
    func dismissStockDetail() {
        showStockDetail = false
        selectedStock = nil
    }
    
    func navigateToMacroDetail(_ type: MacroDataType) {
        selectedMacroType = type
        // Add delay to prevent animation issues
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.showMacroDetail = true
        }
    }
    
    func dismissMacroDetail() {
        showMacroDetail = false
        selectedMacroType = nil
    }
    
    func navigateToNewsDetail(_ news: NewsItem) {
        selectedNews = news
        // Add delay to prevent animation issues
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.showNewsDetail = true
        }
    }
    
    func dismissNewsDetail() {
        showNewsDetail = false
        selectedNews = nil
    }
}