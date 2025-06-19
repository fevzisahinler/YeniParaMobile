import Foundation

// MARK: - Date Formatting Utilities
extension Date {
    // Market trading helpers
    func isMarketOpen() -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: self)
        
        // Weekend check (Saturday = 7, Sunday = 1)
        if weekday == 1 || weekday == 7 {
            return false
        }
        
        // US Market hours: 9:30 AM - 4:00 PM EST
        let components = calendar.dateComponents([.hour, .minute], from: self)
        guard let hour = components.hour, let minute = components.minute else {
            return false
        }
        
        let currentMinutes = hour * 60 + minute
        let marketOpen = 9 * 60 + 30  // 9:30 AM
        let marketClose = 16 * 60      // 4:00 PM
        
        return currentMinutes >= marketOpen && currentMinutes < marketClose
    }
    
    func nextMarketOpen() -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .weekday], from: Date())
        
        // Set to 9:30 AM
        components.hour = 9
        components.minute = 30
        components.second = 0
        
        guard let currentDate = calendar.date(from: components) else { return nil }
        
        // If it's a weekend, move to Monday
        if let weekday = components.weekday {
            if weekday == 7 { // Saturday
                return calendar.date(byAdding: .day, value: 2, to: currentDate)
            } else if weekday == 1 { // Sunday
                return calendar.date(byAdding: .day, value: 1, to: currentDate)
            }
        }
        
        // If market is closed today, return tomorrow's open
        if !isMarketOpen() && Date() < currentDate {
            return currentDate
        } else {
            // Return next business day
            return calendar.date(byAdding: .day, value: 1, to: currentDate)
        }
    }
}
