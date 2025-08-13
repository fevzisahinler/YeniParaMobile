import SwiftUI

struct MarketStatusIndicator: View {
    @State private var isMarketOpen: Bool? = nil
    @State private var marketStatus = "Yükleniyor..."
    @State private var nextSessionTime = ""
    @State private var marketInfo: MarketInfo?
    @State private var hasLoaded = false
    
    private var statusColor: Color {
        switch isMarketOpen {
        case .some(true):
            return Color.green
        case .some(false):
            return Color.red
        case .none:
            return Color.gray
        }
    }
    
    private var statusIndicator: some View {
        Group {
            if let isOpen = isMarketOpen {
                Circle()
                    .fill(isOpen ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .fill(isOpen ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                            .scaleEffect(isOpen ? 1.5 : 1)
                            .opacity(isOpen ? 0 : 1)
                            .animation(hasLoaded ? .easeInOut(duration: 1.5).repeatForever(autoreverses: false) : .none, value: isOpen)
                    )
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            statusIndicator
            
            Text(marketStatus)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(statusColor.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            Task {
                await loadMarketStatus()
            }
            // Update market status every 30 seconds
            Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
                Task {
                    await loadMarketStatus()
                }
            }
        }
    }
    
    private func loadMarketStatus() async {
        do {
            let response = try await APIService.shared.getSP100Symbols()
            if let market = response.data.market {
                await MainActor.run {
                    self.marketInfo = market
                    
                    // Set values without animation on first load
                    if !hasLoaded {
                        self.isMarketOpen = market.isOpen
                        self.hasLoaded = true
                    } else {
                        self.isMarketOpen = market.isOpen
                    }
                    
                    switch market.status.lowercased() {
                    case "open":
                        self.marketStatus = "Açık"
                    case "closed":
                        self.marketStatus = "Kapalı"
                    case "pre-market":
                        self.marketStatus = "Ön Seans"
                    case "after-hours":
                        self.marketStatus = "Kapanış Sonrası"
                    default:
                        self.marketStatus = "Kapalı"
                    }
                }
            }
        } catch {
            // Fallback to local calculation if API fails
            checkMarketStatusLocally()
        }
    }
    
    private func checkMarketStatusLocally() {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.weekday, .hour, .minute], from: now)
        
        guard let weekday = components.weekday,
              let hour = components.hour,
              let minute = components.minute else { return }
        
        // Convert to Turkey time (UTC+3)
        let turkeyHour = (hour + 3) % 24
        let totalMinutes = turkeyHour * 60 + minute
        
        // NYSE: 9:30 AM - 4:00 PM ET
        // In Turkey time: 4:30 PM - 11:00 PM (16:30 - 23:00)
        let marketOpenTime = 16 * 60 + 30  // 16:30
        let marketCloseTime = 23 * 60       // 23:00
        
        // Check if weekend (Saturday = 7, Sunday = 1)
        if weekday == 1 || weekday == 7 {
            isMarketOpen = false
            marketStatus = "Hafta Sonu"
            nextSessionTime = "Pazartesi 16:30"
        } else if totalMinutes >= marketOpenTime && totalMinutes < marketCloseTime {
            isMarketOpen = true
            marketStatus = "Açık"
            let remainingMinutes = marketCloseTime - totalMinutes
            let remainingHours = remainingMinutes / 60
            let remainingMins = remainingMinutes % 60
            if remainingHours > 0 {
                nextSessionTime = "\(remainingHours) saat \(remainingMins) dk"
            } else {
                nextSessionTime = "\(remainingMins) dk"
            }
        } else if totalMinutes < marketOpenTime {
            isMarketOpen = false
            marketStatus = "Kapalı"
            let remainingMinutes = marketOpenTime - totalMinutes
            let remainingHours = remainingMinutes / 60
            let remainingMins = remainingMinutes % 60
            if remainingHours > 0 {
                nextSessionTime = "\(remainingHours) saat \(remainingMins) dk"
            } else {
                nextSessionTime = "\(remainingMins) dk"
            }
        } else {
            isMarketOpen = false
            marketStatus = "Kapalı"
            nextSessionTime = "Yarın 16:30"
        }
    }
}