import Foundation

// MARK: - User Defaults Repository
final class UserDefaultsRepository {
    static let shared = UserDefaultsRepository()
    
    private let userDefaults: UserDefaults
    private let suiteName: String?
    
    init(userDefaults: UserDefaults = .standard, suiteName: String? = nil) {
        if let suiteName = suiteName {
            self.userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        } else {
            self.userDefaults = userDefaults
        }
        self.suiteName = suiteName
    }
    
    // MARK: - Generic Methods
    func set<T: Codable>(_ object: T, for key: String) {
        if let data = try? JSONEncoder().encode(object) {
            userDefaults.set(data, forKey: key)
        }
    }
    
    func get<T: Codable>(_ type: T.Type, for key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    func remove(for key: String) {
        userDefaults.removeObject(forKey: key)
    }
    
    // MARK: - Specific Methods
    func setString(_ value: String, for key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    func getString(for key: String) -> String? {
        return userDefaults.string(forKey: key)
    }
    
    func setBool(_ value: Bool, for key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    func getBool(for key: String) -> Bool {
        return userDefaults.bool(forKey: key)
    }
    
    func setInt(_ value: Int, for key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    func getInt(for key: String) -> Int {
        return userDefaults.integer(forKey: key)
    }
    
    func setDouble(_ value: Double, for key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    func getDouble(for key: String) -> Double {
        return userDefaults.double(forKey: key)
    }
    
    func setDate(_ date: Date, for key: String) {
        userDefaults.set(date, forKey: key)
    }
    
    func getDate(for key: String) -> Date? {
        return userDefaults.object(forKey: key) as? Date
    }
    
    func setArray<T: Codable>(_ array: [T], for key: String) {
        if let data = try? JSONEncoder().encode(array) {
            userDefaults.set(data, forKey: key)
        }
    }
    
    func getArray<T: Codable>(_ type: T.Type, for key: String) -> [T]? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode([T].self, from: data)
    }
    
    // MARK: - App Settings
    func getAppSettings() -> AppSettings {
        return get(AppSettings.self, for: "appSettings") ?? AppSettings()
    }
    
    func saveAppSettings(_ settings: AppSettings) {
        set(settings, for: "appSettings")
    }
    
    // MARK: - Batch Operations
    func setMultiple(_ values: [String: Any]) {
        values.forEach { key, value in
            userDefaults.set(value, forKey: key)
        }
        userDefaults.synchronize()
    }
    
    func removeMultiple(_ keys: [String]) {
        keys.forEach { key in
            userDefaults.removeObject(forKey: key)
        }
        userDefaults.synchronize()
    }
    
    func removeAll() {
        if let suiteName = suiteName {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        } else {
            if let bundleId = Bundle.main.bundleIdentifier {
                userDefaults.removePersistentDomain(forName: bundleId)
            }
        }
        userDefaults.synchronize()
    }
    
    // MARK: - Key Existence
    func hasKey(_ key: String) -> Bool {
        return userDefaults.object(forKey: key) != nil
    }
    
    // MARK: - Migration
    func migrateKey(from oldKey: String, to newKey: String) {
        if let value = userDefaults.object(forKey: oldKey) {
            userDefaults.set(value, forKey: newKey)
            userDefaults.removeObject(forKey: oldKey)
            userDefaults.synchronize()
        }
    }
}

// MARK: - App Settings Model
struct AppSettings: Codable {
    var enableNotifications: Bool = true
    var enableBiometricAuth: Bool = false
    var preferredLanguage: String = "tr"
    var theme: AppTheme = .dark
    var enableHapticFeedback: Bool = true
    var autoRefreshInterval: TimeInterval = 30
    var chartType: ChartType = .line
    var showPercentageChange: Bool = true
    
    enum AppTheme: String, Codable, CaseIterable {
        case light = "light"
        case dark = "dark"
        case system = "system"
        
        var displayName: String {
            switch self {
            case .light: return "Açık"
            case .dark: return "Koyu"
            case .system: return "Sistem"
            }
        }
    }
    
    enum ChartType: String, Codable, CaseIterable {
        case line = "line"
        case candle = "candle"
        case area = "area"
        
        var displayName: String {
            switch self {
            case .line: return "Çizgi"
            case .candle: return "Mum"
            case .area: return "Alan"
            }
        }
    }
}
