import Foundation
import Combine

@MainActor
final class MarketDataRefreshManager: ObservableObject {
    static let shared = MarketDataRefreshManager()
    
    @Published var lastRefreshTime: Date = Date()
    @Published var isRefreshing: Bool = false
    
    private var refreshTimer: Timer?
    private var refreshInterval: TimeInterval = 60.0 // 60 seconds
    private var subscribers = Set<AnyCancellable>()
    
    // Notification for manual refresh triggers
    static let refreshNotification = Notification.Name("MarketDataRefreshNotification")
    
    private init() {
        startAutoRefresh()
    }
    
    func startAutoRefresh() {
        stopAutoRefresh() // Clear any existing timer
        
        // Initial refresh
        Task {
            await performRefresh()
        }
        
        // Schedule periodic refresh
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                await self?.performRefresh()
            }
        }
    }
    
    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    func performRefresh() async {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        lastRefreshTime = Date()
        
        // Post notification for all listeners to refresh
        NotificationCenter.default.post(name: Self.refreshNotification, object: nil)
        
        // Add a small delay to prevent rapid refreshes
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
        
        isRefreshing = false
    }
    
    func manualRefresh() async {
        // Reset timer to start fresh 60-second cycle
        stopAutoRefresh()
        await performRefresh()
        startAutoRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}