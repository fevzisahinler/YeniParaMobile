import Foundation
import UIKit

// MARK: - Cache Manager Protocol
protocol CacheManagerProtocol {
    func get<T: Codable>(key: String) async -> T?
    func set<T: Codable>(_ object: T, key: String, expiry: TimeInterval?) async
    func remove(key: String) async
    func clearAll() async
    func getImage(key: String) async -> Data?
    func setImage(_ data: Data, key: String, expiry: TimeInterval?) async
}

// MARK: - Cache Manager Implementation
final actor CacheManager: CacheManagerProtocol {
    // MARK: - Properties
    static let shared = CacheManager()
    
    private let memoryCache = NSCache<NSString, CacheEntry>()
    private let diskCache: DiskCache
    private let maxMemoryCost: Int = 50 * 1024 * 1024 // 50MB
    private let maxDiskSize: Int = 200 * 1024 * 1024 // 200MB
    
    // MARK: - Initialization
    init() {
        self.diskCache = DiskCache()
        
        // Configure memory cache
        memoryCache.totalCostLimit = maxMemoryCost
        memoryCache.countLimit = 100
        
        // Listen for memory warnings
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.clearMemoryCache()
            }
        }
    }
    
    // MARK: - Public Methods
    func get<T: Codable>(key: String) async -> T? {
        let cacheKey = NSString(string: key)
        
        // Check memory cache first
        if let entry = memoryCache.object(forKey: cacheKey) {
            if !entry.isExpired {
                return entry.object as? T
            } else {
                memoryCache.removeObject(forKey: cacheKey)
            }
        }
        
        // Check disk cache
        if let data = await diskCache.getData(for: key),
           let object = try? JSONDecoder().decode(T.self, from: data) {
            // Store in memory cache for faster access
            let entry = CacheEntry(object: object, expiry: nil)
            memoryCache.setObject(entry, forKey: cacheKey, cost: data.count)
            return object
        }
        
        return nil
    }
    
    func set<T: Codable>(_ object: T, key: String, expiry: TimeInterval? = nil) async {
        let cacheKey = NSString(string: key)
        let expiryDate = expiry.map { Date().addingTimeInterval($0) }
        
        // Store in memory cache
        let entry = CacheEntry(object: object, expiry: expiryDate)
        memoryCache.setObject(entry, forKey: cacheKey)
        
        // Store in disk cache
        if let data = try? JSONEncoder().encode(object) {
            await diskCache.setData(data, for: key, expiry: expiryDate)
        }
    }
    
    func remove(key: String) async {
        let cacheKey = NSString(string: key)
        memoryCache.removeObject(forKey: cacheKey)
        await diskCache.removeData(for: key)
    }
    
    func clearAll() async {
        memoryCache.removeAllObjects()
        await diskCache.clearAll()
    }
    
    func getImage(key: String) async -> Data? {
        // Check memory cache
        let cacheKey = NSString(string: "image_\(key)")
        if let entry = memoryCache.object(forKey: cacheKey),
           !entry.isExpired,
           let data = entry.object as? Data {
            return data
        }
        
        // Check disk cache
        return await diskCache.getData(for: "image_\(key)")
    }
    
    func setImage(_ data: Data, key: String, expiry: TimeInterval? = nil) async {
        let cacheKey = NSString(string: "image_\(key)")
        let expiryDate = expiry.map { Date().addingTimeInterval($0) }
        
        // Store in memory cache with cost
        let entry = CacheEntry(object: data, expiry: expiryDate)
        memoryCache.setObject(entry, forKey: cacheKey, cost: data.count)
        
        // Store in disk cache
        await diskCache.setData(data, for: "image_\(key)", expiry: expiryDate)
    }
    
    // MARK: - Private Methods
    private func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }
}

// MARK: - Cache Entry
private class CacheEntry: NSObject {
    let object: Any
    let expiry: Date?
    
    init(object: Any, expiry: Date?) {
        self.object = object
        self.expiry = expiry
    }
    
    var isExpired: Bool {
        guard let expiry = expiry else { return false }
        return Date() > expiry
    }
}

// MARK: - Disk Cache
private actor DiskCache {
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    private let maxSize: Int = 200 * 1024 * 1024 // 200MB
    
    init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        self.cacheDirectory = paths[0].appendingPathComponent("YeniParaCache")
        
        // Create directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Clean expired items on init
        Task {
            await cleanExpiredItems()
        }
    }
    
    func getData(for key: String) -> Data? {
        let fileURL = cacheDirectory.appendingPathComponent(key.md5)
        
        // Check if file exists
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        // Check expiry
        if let metadata = getMetadata(for: key),
           let expiry = metadata.expiry,
           Date() > expiry {
            try? fileManager.removeItem(at: fileURL)
            removeMetadata(for: key)
            return nil
        }
        
        return try? Data(contentsOf: fileURL)
    }
    
    func setData(_ data: Data, for key: String, expiry: Date?) {
        let fileURL = cacheDirectory.appendingPathComponent(key.md5)
        
        // Write data
        try? data.write(to: fileURL)
        
        // Save metadata
        let metadata = CacheMetadata(key: key, size: data.count, expiry: expiry)
        saveMetadata(metadata, for: key)
        
        // Check disk size
        Task {
            await checkDiskSize()
        }
    }
    
    func removeData(for key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key.md5)
        try? fileManager.removeItem(at: fileURL)
        removeMetadata(for: key)
    }
    
    func clearAll() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    private func cleanExpiredItems() {
        let metadataURL = cacheDirectory.appendingPathComponent("metadata.plist")
        
        guard let metadata = NSDictionary(contentsOf: metadataURL) as? [String: Data] else { return }
        
        var newMetadata = [String: Data]()
        
        for (key, data) in metadata {
            if let meta = try? JSONDecoder().decode(CacheMetadata.self, from: data) {
                if let expiry = meta.expiry, Date() > expiry {
                    // Remove expired file
                    let fileURL = cacheDirectory.appendingPathComponent(key)
                    try? fileManager.removeItem(at: fileURL)
                } else {
                    newMetadata[key] = data
                }
            }
        }
        
        // Save updated metadata
        (newMetadata as NSDictionary).write(to: metadataURL, atomically: true)
    }
    
    private func checkDiskSize() async {
        let metadataURL = cacheDirectory.appendingPathComponent("metadata.plist")
        
        guard let metadata = NSDictionary(contentsOf: metadataURL) as? [String: Data] else { return }
        
        var totalSize = 0
        var items: [(key: String, metadata: CacheMetadata, accessDate: Date)] = []
        
        // Calculate total size and collect items
        for (key, data) in metadata {
            if let meta = try? JSONDecoder().decode(CacheMetadata.self, from: data) {
                totalSize += meta.size
                
                let fileURL = cacheDirectory.appendingPathComponent(key)
                let accessDate = (try? fileManager.attributesOfItem(atPath: fileURL.path)[.modificationDate] as? Date) ?? Date.distantPast
                
                items.append((key: key, metadata: meta, accessDate: accessDate))
            }
        }
        
        // If over limit, remove least recently used items
        if totalSize > maxSize {
            // Sort by access date (oldest first)
            items.sort { $0.accessDate < $1.accessDate }
            
            var currentSize = totalSize
            for item in items {
                if currentSize <= maxSize { break }
                
                // Remove item
                removeData(for: item.metadata.key)
                currentSize -= item.metadata.size
            }
        }
    }
    
    private func getMetadata(for key: String) -> CacheMetadata? {
        let metadataURL = cacheDirectory.appendingPathComponent("metadata.plist")
        guard let metadata = NSDictionary(contentsOf: metadataURL) as? [String: Data],
              let data = metadata[key.md5] else { return nil }
        
        return try? JSONDecoder().decode(CacheMetadata.self, from: data)
    }
    
    private func saveMetadata(_ metadata: CacheMetadata, for key: String) {
        let metadataURL = cacheDirectory.appendingPathComponent("metadata.plist")
        
        var allMetadata = (NSDictionary(contentsOf: metadataURL) as? [String: Data]) ?? [:]
        
        if let data = try? JSONEncoder().encode(metadata) {
            allMetadata[key.md5] = data
            (allMetadata as NSDictionary).write(to: metadataURL, atomically: true)
        }
    }
    
    private func removeMetadata(for key: String) {
        let metadataURL = cacheDirectory.appendingPathComponent("metadata.plist")
        
        var allMetadata = (NSDictionary(contentsOf: metadataURL) as? [String: Data]) ?? [:]
        allMetadata.removeValue(forKey: key.md5)
        
        (allMetadata as NSDictionary).write(to: metadataURL, atomically: true)
    }
}

// MARK: - Cache Metadata
private struct CacheMetadata: Codable {
    let key: String
    let size: Int
    let expiry: Date?
}

// MARK: - String Extension for MD5
private extension String {
    var md5: String {
        // Simple hash for cache key
        let data = Data(self.utf8)
        return data.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
    }
}
