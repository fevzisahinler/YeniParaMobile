import SwiftUI

class NavigationManager: ObservableObject {
    @Published var selectedStock: String? = nil
    @Published var showStockDetail = false
    
    func navigateToStock(_ symbol: String) {
        print("DEBUG: NavigationManager - navigateToStock called with symbol: \(symbol)")
        selectedStock = symbol
        showStockDetail = true
        print("DEBUG: NavigationManager - showStockDetail: \(showStockDetail), selectedStock: \(String(describing: selectedStock))")
    }
    
    func dismissStockDetail() {
        showStockDetail = false
        selectedStock = nil
    }
}