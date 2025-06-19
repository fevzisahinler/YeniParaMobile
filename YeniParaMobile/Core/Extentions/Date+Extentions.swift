import Foundation

// MARK: - Date Extensions
extension Date {
    // MARK: - Static Dates
    static var now: Date {
        Date()
    }
    
    static var yesterday: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    }
    
    static var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }
    
    // MARK: - Components
    var year: Int {
        Calendar.current.component(.year, from: self)
    }
    
    var month: Int {
        Calendar.current.component(.month, from: self)
    }
    
    var day: Int {
        Calendar.current.component(.day, from: self)
    }
    
    var hour: Int {
        Calendar.current.component(.hour, from: self)
    }
    
    var minute: Int {
        Calendar.current.component(.minute, from: self)
    }
    
    var second: Int {
        Calendar.current.component(.second, from: self)
    }
    
    var weekday: Int {
        Calendar.current.component(.weekday, from: self)
    }
    
    // MARK: - Comparisons
    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }
    
    func isSameMonth(as date: Date) -> Bool {
        year == date.year && month == date.month
    }
    
    func isSameYear(as date: Date) -> Bool {
        year == date.year
    }
    
    var isToday: Bool {
        isSameDay(as: Date())
    }
    
    var isYesterday: Bool {
        isSameDay(as: Date.yesterday)
    }
    
    var isTomorrow: Bool {
        isSameDay(as: Date.tomorrow)
    }
    
    var isPast: Bool {
        self < Date()
    }
    
    var isFuture: Bool {
        self > Date()
    }
    
    // MARK: - Adding/Subtracting
    func adding(_ component: Calendar.Component, value: Int) -> Date {
        Calendar.current.date(byAdding: component, value: value, to: self) ?? self
    }
    
    func subtracting(_ component: Calendar.Component, value: Int) -> Date {
        adding(component, value: -value)
    }
    
    // MARK: - Time Intervals
    var timeIntervalSinceNow: TimeInterval {
        -self.timeIntervalSinceNow
    }
    
    func timeInterval(to date: Date) -> TimeInterval {
        date.timeIntervalSince(self)
    }
    
    // MARK: - Start/End of Period
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? self
    }
    
    var startOfWeek: Date {
        Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: self).date ?? self
    }
    
    var endOfWeek: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: startOfWeek)?.subtracting(.second, value: 1) ?? self
    }
    
    var startOfMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self)) ?? self
    }
    
    var endOfMonth: Date {
        Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) ?? self
    }
    
    var startOfYear: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year], from: self)) ?? self
    }
    
    var endOfYear: Date {
        Calendar.current.date(from: DateComponents(year: year, month: 12, day: 31)) ?? self
    }
    
    // MARK: - Relative Time
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    var timeAgo: String {
        let now = Date()
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self, to: now)
        
        if let year = components.year, year > 0 {
            return year == 1 ? "1 yıl önce" : "\(year) yıl önce"
        } else if let month = components.month, month > 0 {
            return month == 1 ? "1 ay önce" : "\(month) ay önce"
        } else if let day = components.day, day > 0 {
            return day == 1 ? "Dün" : "\(day) gün önce"
        } else if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1 saat önce" : "\(hour) saat önce"
        } else if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1 dakika önce" : "\(minute) dakika önce"
        } else {
            return "Az önce"
        }
    }
}

// MARK: - Date Formatting
extension Date {
    // MARK: - Common Formats
    var formatted: String {
        DateFormatterHelper.shared.string(from: self, format: .dateTime)
    }
    
    var dateFormatted: String {
        DateFormatterHelper.shared.string(from: self, format: .date)
    }
    
    var timeFormatted: String {
        DateFormatterHelper.shared.string(from: self, format: .time)
    }
    
    var shortDateFormatted: String {
        DateFormatterHelper.shared.string(from: self, format: .shortDate)
    }
    
    var fullDateFormatted: String {
        DateFormatterHelper.shared.string(from: self, format: .fullDate)
    }
    
    // MARK: - Custom Format
    func formatted(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: self)
    }
}

// MARK: - Date Formatter Helper
final class DateFormatterHelper {
    static let shared = DateFormatterHelper()
    
    enum Format {
        case date           // 15 Ocak 2025
        case time           // 14:30
        case dateTime       // 15 Ocak 2025 14:30
        case shortDate      // 15/01/2025
        case fullDate       // 15 Ocak 2025 Çarşamba
        case iso8601        // 2025-01-15T14:30:00Z
        case custom(String)
    }
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    private lazy var iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    func string(from date: Date, format: Format) -> String {
        switch format {
        case .date:
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .none
            return dateFormatter.string(from: date)
            
        case .time:
            dateFormatter.dateStyle = .none
            dateFormatter.timeStyle = .short
            return dateFormatter.string(from: date)
            
        case .dateTime:
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            return dateFormatter.string(from: date)
            
        case .shortDate:
            dateFormatter.dateFormat = "dd/MM/yyyy"
            return dateFormatter.string(from: date)
            
        case .fullDate:
            dateFormatter.dateFormat = "dd MMMM yyyy EEEE"
            return dateFormatter.string(from: date)
            
        case .iso8601:
            return iso8601Formatter.string(from: date)
            
        case .custom(let format):
            dateFormatter.dateFormat = format
            return dateFormatter.string(from: date)
        }
    }
    
    func date(from string: String, format: Format) -> Date? {
        switch format {
        case .iso8601:
            return iso8601Formatter.date(from: string)
        case .custom(let format):
            dateFormatter.dateFormat = format
            return dateFormatter.date(from: string)
        default:
            return nil
        }
    }
}

// MARK: - TimeInterval Extensions
extension TimeInterval {
    var formatted: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) % 3600 / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var inMinutes: Double {
        self / 60
    }
    
    var inHours: Double {
        self / 3600
    }
    
    var inDays: Double {
        self / 86400
    }
}
