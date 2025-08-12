import SwiftUI

struct MarketStatusIndicator: View {
    @State private var isMarketOpen = false
    @State private var marketStatus = "Kapalı"
    @State private var nextSessionTime = ""
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isMarketOpen ? Color.green : Color.red)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .fill(isMarketOpen ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isMarketOpen ? 1.5 : 1)
                        .opacity(isMarketOpen ? 0 : 1)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: isMarketOpen)
                )
            
            Text(marketStatus)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isMarketOpen ? Color.green : Color.red)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill((isMarketOpen ? Color.green : Color.red).opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke((isMarketOpen ? Color.green : Color.red).opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            checkMarketStatus()
            // Update market status every minute
            Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                checkMarketStatus()
            }
        }
    }
    
    private func checkMarketStatus() {
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