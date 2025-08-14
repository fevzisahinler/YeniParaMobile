import SwiftUI

struct StockLogoView: View {
    let symbol: String
    let logoPath: String?
    let size: CGFloat
    let authToken: String?
    
    @State private var uiImage: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else if isLoading {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: size, height: size)
            } else {
                // Fallback - show symbol initials
                Text(String(symbol.prefix(2)))
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundColor(AppColors.primary)
                    .frame(width: size, height: size)
            }
        }
        .onAppear {
            loadLogo()
        }
    }
    
    private func loadLogo() {
        Task {
            let cacheKey = logoPath ?? symbol
            
            // Check cache first
            if let cachedImage = await ImageCacheManager.shared.image(for: cacheKey) {
                await MainActor.run {
                    self.uiImage = cachedImage
                    self.isLoading = false
                }
                return
            }
            
            // Use IP address for both simulator and device
            let baseURL = "http://192.168.1.210:4000"
            
            // Use logoPath if provided, otherwise construct from symbol
            let path = logoPath ?? "/api/v1/logos/\(symbol).jpeg"
            
            guard let url = URL(string: "\(baseURL)\(path)") else {
                await MainActor.run {
                    self.isLoading = false
                }
                return
            }
            
            var request = URLRequest(url: url)
            request.cachePolicy = .returnCacheDataElseLoad
            
            // Add auth token if available
            if let token = authToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                // Check if we got image data
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200,
                   let image = UIImage(data: data) {
                    
                    // Store in cache
                    ImageCacheManager.shared.store(data, for: cacheKey)
                    
                    await MainActor.run {
                        self.uiImage = image
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
}