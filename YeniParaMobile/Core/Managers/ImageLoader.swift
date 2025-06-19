import SwiftUI
import Combine

// MARK: - Image Loader Manager
final class ImageLoader: ObservableObject {
    // MARK: - Properties
    @Published var image: UIImage?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let url: URL
    private let cacheManager: CacheManager
    private var cancellable: AnyCancellable?
    
    // MARK: - Initialization
    init(url: URL, cacheManager: CacheManager = .shared) {
        self.url = url
        self.cacheManager = cacheManager
    }
    
    deinit {
        cancel()
    }
    
    // MARK: - Public Methods
    func load() {
        guard image == nil else { return }
        
        isLoading = true
        error = nil
        
        Task {
            await loadImage()
        }
    }
    
    func cancel() {
        cancellable?.cancel()
    }
    
    // MARK: - Private Methods
    private func loadImage() async {
        // Check cache first
        let cacheKey = url.absoluteString
        if let cachedData = await cacheManager.getImage(key: cacheKey),
           let cachedImage = UIImage(data: cachedData) {
            await MainActor.run {
                self.image = cachedImage
                self.isLoading = false
            }
            return
        }
        
        // Download image
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let downloadedImage = UIImage(data: data) else {
                throw ImageLoadError.invalidData
            }
            
            // Cache image
            await cacheManager.setImage(data, key: cacheKey, expiry: 86400) // 24 hours
            
            await MainActor.run {
                self.image = downloadedImage
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
}

// MARK: - Image Load Error
enum ImageLoadError: LocalizedError {
    case invalidData
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Geçersiz görsel verisi"
        case .networkError:
            return "Ağ bağlantısı hatası"
        }
    }
}

// MARK: - Async Image View
struct CachedAsyncImage: View {
    let url: URL?
    let placeholder: AnyView
    let content: (Image) -> AnyView
    
    @StateObject private var loader: ImageLoader
    
    init(
        url: URL?,
        @ViewBuilder placeholder: () -> some View = { ProgressView() },
        @ViewBuilder content: @escaping (Image) -> some View
    ) {
        self.url = url
        self.placeholder = AnyView(placeholder())
        self.content = { AnyView(content($0)) }
        
        if let url = url {
            self._loader = StateObject(wrappedValue: ImageLoader(url: url))
        } else {
            self._loader = StateObject(wrappedValue: ImageLoader(url: URL(string: "https://placeholder.com")!))
        }
    }
    
    var body: some View {
        Group {
            if let image = loader.image {
                content(Image(uiImage: image))
            } else if loader.isLoading {
                placeholder
            } else if loader.error != nil {
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            } else {
                placeholder
            }
        }
        .onAppear {
            if url != nil {
                loader.load()
            }
        }
    }
}

// MARK: - Logo Image Loader
struct LogoImageView: View {
    let path: String
    let size: CGFloat
    let stockCode: String
    let authToken: String?
    
    private var logoURL: URL? {
        URL(string: "http://192.168.1.210:4000\(path)")
    }
    
    var body: some View {
        if let token = authToken, let url = logoURL {
            AuthenticatedAsyncImage(
                url: url,
                token: token,
                size: size,
                fallbackCode: stockCode
            )
        } else {
            // Fallback logo
            FallbackLogoView(code: stockCode, size: size)
        }
    }
}

// MARK: - Authenticated Async Image
struct AuthenticatedAsyncImage: View {
    let url: URL
    let token: String
    let size: CGFloat
    let fallbackCode: String
    
    @State private var imageData: Data?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
            } else if isLoading {
                RoundedRectangle(cornerRadius: size * 0.2)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: size, height: size)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                            .scaleEffect(0.5)
                    )
            } else {
                FallbackLogoView(code: fallbackCode, size: size)
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        // Check cache first
        let cacheKey = url.absoluteString
        if let cachedData = await CacheManager.shared.getImage(key: cacheKey) {
            await MainActor.run {
                self.imageData = cachedData
                self.isLoading = false
            }
            return
        }
        
        // Download with auth
        do {
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("iOS", forHTTPHeaderField: "X-Platform")
            request.timeoutInterval = 10
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                // Cache the image
                await CacheManager.shared.setImage(data, key: cacheKey, expiry: 86400)
                
                await MainActor.run {
                    self.imageData = data
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

// MARK: - Fallback Logo View
struct FallbackLogoView: View {
    let code: String
    let size: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.2)
            .fill(
                LinearGradient(
                    colors: [AppColors.primary.opacity(0.8), AppColors.secondary.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay(
                Text(String(code.prefix(2)))
                    .font(.system(size: size * 0.35, weight: .bold))
                    .foregroundColor(.white)
            )
    }
}

// MARK: - Image Cache Manager
final class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    private let cache = NSCache<NSString, UIImage>()
    private let diskCacheURL: URL
    
    init() {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        diskCacheURL = paths[0].appendingPathComponent("ImageCache")
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        
        // Configure memory cache
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    func image(for key: String) -> UIImage? {
        // Check memory cache
        if let image = cache.object(forKey: key as NSString) {
            return image
        }
        
        // Check disk cache
        let fileURL = diskCacheURL.appendingPathComponent(key.md5)
        if let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            // Store in memory cache
            cache.setObject(image, forKey: key as NSString, cost: data.count)
            return image
        }
        
        return nil
    }
    
    func store(_ image: UIImage, for key: String) {
        // Store in memory cache
        cache.setObject(image, forKey: key as NSString)
        
        // Store in disk cache
        if let data = image.jpegData(compressionQuality: 0.8) {
            let fileURL = diskCacheURL.appendingPathComponent(key.md5)
            try? data.write(to: fileURL)
        }
    }
    
    func clearCache() {
        cache.removeAllObjects()
        try? FileManager.default.removeItem(at: diskCacheURL)
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }
}

// MARK: - String Extension for MD5
private extension String {
    var md5: String {
        let data = Data(self.utf8)
        return data.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
    }
}
