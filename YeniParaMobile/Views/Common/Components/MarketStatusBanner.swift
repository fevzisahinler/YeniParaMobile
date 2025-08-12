import SwiftUI

struct MarketStatusBanner: View {
    @State private var currentTime = Date()
    @State private var timer: Timer?
    
    private var marketStatus: MarketStatus {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        let weekday = calendar.component(.weekday, from: currentTime)
        
        // Hafta sonu kontrolü (Cumartesi = 7, Pazar = 1)
        if weekday == 1 || weekday == 7 {
            return .closed
        }
        
        // Borsa saatleri (09:30 - 18:00 TSİ)
        let totalMinutes = hour * 60 + minute
        let openTime = 9 * 60 + 30  // 09:30
        let closeTime = 18 * 60      // 18:00
        
        if totalMinutes >= openTime && totalMinutes < closeTime {
            return .open
        } else if totalMinutes >= (openTime - 30) && totalMinutes < openTime {
            return .preMarket
        } else if totalMinutes >= closeTime && totalMinutes < (closeTime + 30) {
            return .afterHours
        } else {
            return .closed
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Market Status Indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(marketStatus.color)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .fill(marketStatus.color.opacity(0.3))
                                .frame(width: 16, height: 16)
                                .blur(radius: 2)
                        )
                    
                    Text(marketStatus.text)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(marketStatus.color)
                }
                
                Divider()
                    .frame(height: 16)
                    .background(AppColors.textTertiary.opacity(0.3))
                
                // Market Hours Info
                Text(marketStatus.hoursText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                
                Spacer()
                
                // Data Delay Warning
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color.orange)
                    
                    Text("15 dk gecikmeli")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.15))
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [
                        AppColors.cardBackground,
                        AppColors.cardBackground.opacity(0.7)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppColors.cardBorder)
                    .offset(y: -0.5),
                alignment: .bottom
            )
        }
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                currentTime = Date()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
}

enum MarketStatus {
    case open
    case closed
    case preMarket
    case afterHours
    
    var text: String {
        switch self {
        case .open:
            return "Piyasa Açık"
        case .closed:
            return "Piyasa Kapalı"
        case .preMarket:
            return "Açılış Öncesi"
        case .afterHours:
            return "Kapanış Sonrası"
        }
    }
    
    var color: Color {
        switch self {
        case .open:
            return AppColors.primary
        case .closed:
            return AppColors.error
        case .preMarket, .afterHours:
            return Color.orange
        }
    }
    
    var hoursText: String {
        switch self {
        case .open:
            return "09:30 - 18:00 TSİ"
        case .closed:
            return "Piyasa saatleri: 09:30 - 18:00 TSİ"
        case .preMarket:
            return "Açılışa kalan süre hesaplanıyor..."
        case .afterHours:
            return "Kapanış sonrası işlemler"
        }
    }
}