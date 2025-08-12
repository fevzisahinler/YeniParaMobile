import Foundation

struct TimeFormatter {
    static func formatTimeAgo(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else {
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: dateString) else {
                // Try simple format
                let simpleFormatter = DateFormatter()
                simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                guard let date = simpleFormatter.date(from: dateString) else {
                    return "Bilinmiyor"
                }
                return formatTimeDifference(from: date)
            }
            return formatTimeDifference(from: date)
        }
        
        return formatTimeDifference(from: date)
    }
    
    private static func formatTimeDifference(from date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date, to: now)
        
        if let years = components.year, years > 0 {
            return "\(years) yıl önce"
        } else if let months = components.month, months > 0 {
            return "\(months) ay önce"
        } else if let days = components.day, days > 0 {
            return "\(days) gün önce"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) saat önce"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes) dakika önce"
        } else {
            return "Az önce"
        }
    }
    
    static func formatMemberSince(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else {
            return "Bilinmiyor"
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.locale = Locale(identifier: "tr_TR")
        return displayFormatter.string(from: date)
    }
}