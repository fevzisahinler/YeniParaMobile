import SwiftUI
import Combine

class NavigationManager: ObservableObject {
    @Published var selectedStock: String? = nil
    @Published var showStockDetail = false
    @Published var selectedMacroType: MacroDataType? = nil
    @Published var showMacroDetail = false
    @Published var selectedNews: NewsItem? = nil
    @Published var showNewsDetail = false
    
    private var cancellables = Set<AnyCancellable>()
    private var navigationWorkItem: DispatchWorkItem?
    
    init() {
        // Ensure clean state on init
        self.selectedStock = nil
        self.showStockDetail = false
    }
    
    func navigateToStock(_ symbol: String) {
        // Don't reset if we're already navigating to the same symbol
        if selectedStock == symbol && showStockDetail {
            return
        }
        
        // Cancel any pending navigation
        navigationWorkItem?.cancel()
        
        // First, ensure everything is clean
        if showStockDetail {
            showStockDetail = false
            selectedStock = nil
        }
        
        // Create new navigation work
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            self.selectedStock = symbol
            
            // Give UI time to register the symbol change
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                guard self.selectedStock == symbol else { return }
                self.showStockDetail = true
            }
        }
        
        navigationWorkItem = workItem
        
        // Execute with delay to ensure UI is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }
    
    func dismissStockDetail() {
        // Only dismiss if we're actually showing the detail
        guard showStockDetail else { return }
        
        showStockDetail = false
        navigationWorkItem?.cancel()
        navigationWorkItem = nil
        
        // Clear selected stock after sheet is fully dismissed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.selectedStock = nil
        }
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