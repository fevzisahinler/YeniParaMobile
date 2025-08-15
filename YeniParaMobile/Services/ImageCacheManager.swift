import Foundation
import UIKit

final class ImageCacheManager: @unchecked Sendable {
    static let shared = ImageCacheManager()
    
    private let cache = NSCache<NSString, NSData>()
    private let diskCacheURL: URL
    private let ioQueue = DispatchQueue(label: "com.yenipara.imagecache", qos: .background)
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
        
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheURL = cacheDirectory.appendingPathComponent("ImageCache")
        
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        
        cleanOldCache()
    }
    
    func image(for key: String) async -> UIImage? {
        // Check memory cache
        if let data = cache.object(forKey: key as NSString) {
            return UIImage(data: data as Data)
        }
        
        // Check disk cache
        return await withCheckedContinuation { continuation in
            ioQueue.async {
                let fileURL = self.diskCacheURL.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key)
                if let data = try? Data(contentsOf: fileURL),
                   let image = UIImage(data: data) {
                    self.cache.setObject(data as NSData, forKey: key as NSString, cost: data.count)
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    func store(_ data: Data, for key: String) {
        cache.setObject(data as NSData, forKey: key as NSString, cost: data.count)
        
        ioQueue.async {
            let fileURL = self.diskCacheURL.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key)
            try? data.write(to: fileURL)
        }
    }
    
    private func cleanOldCache() {
        ioQueue.async {
            let fileManager = FileManager.default
            let expirationDate = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days
            
            guard let files = try? fileManager.contentsOfDirectory(at: self.diskCacheURL, includingPropertiesForKeys: [.contentModificationDateKey]) else { return }
            
            for file in files {
                if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
                   let modificationDate = attributes[.modificationDate] as? Date,
                   modificationDate < expirationDate {
                    try? fileManager.removeItem(at: file)
                }
            }
        }
    }
    
    func clearCache() {
        cache.removeAllObjects()
        
        ioQueue.async {
            try? FileManager.default.removeItem(at: self.diskCacheURL)
            try? FileManager.default.createDirectory(at: self.diskCacheURL, withIntermediateDirectories: true)
        }
    }
}