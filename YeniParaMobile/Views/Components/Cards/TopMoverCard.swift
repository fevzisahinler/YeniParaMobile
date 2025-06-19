import SwiftUI

struct TopMoverCard: View {
    let stock: UISymbol
    let isGainer: Bool
    let isFavorite: Bool
    let matchScore: Int
    let onFavoriteToggle: () -> Void
    
    @State private var isPressed = false
    
    private var cardGradient: LinearGradient {
        if isGainer {
            return LinearGradient(
                colors: [AppColors.primary.opacity(0.15), AppColors.primary.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [AppColors.error.opacity(0.15), AppColors.error.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                // Match Score Badge
                Text("%\(matchScore)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isGainer ? AppColors.primary : AppColors.error)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill((isGainer ? AppColors.primary : AppColors.error).opacity(0.1))
                    )
                
                Spacer()
                
                // Favorite Button
                Button(action: onFavoriteToggle) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 14))
                        .foregroundColor(isFavorite ? AppColors.error : AppColors.textSecondary)
                }
            }
            
            // Stock Logo
            StockLogoView(
                logoPath: stock.logoPath,
                stockCode: stock.code,
                size: 40
            )
            
            // Stock Info
            VStack(spacing: 8) {
                Text(stock.code)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(stock.name)
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
            
            // Price and Change
            VStack(spacing: 4) {
                Text(stock.formattedPrice)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: 4) {
                    Image(systemName: isGainer ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10))
                    
                    Text(stock.formattedChangePercent)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(stock.changeColor)
            }
        }
        .padding(16)
        .frame(width: 140)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke((isGainer ? AppColors.primary : AppColors.error).opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                isPressed = pressing
            },
            perform: {}
        )
    }
}
struct StockLogoView: View {
    let logoPath: String
    let stockCode: String
    let size: CGFloat
    let authToken: String? = TokenManager.shared.accessToken
    
    @State private var logoData: Data?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if let logoData = logoData, let uiImage = UIImage(data: logoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
            } else if isLoading {
                RoundedRectangle(cornerRadius: size * 0.2)
                    .fill(AppColors.cardBackground)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                            .scaleEffect(0.5)
                    )
            } else {
                // Fallback logo
                RoundedRectangle(cornerRadius: size * 0.2)
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary.opacity(0.8), AppColors.secondary.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Text(String(stockCode.prefix(2)))
                            .font(.system(size: size * 0.35, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
        }
        .frame(width: size, height: size)
        .task {
            await loadLogo()
        }
    }
    
    private func loadLogo() async {
        guard let token = authToken,
              let url = URL(string: "\(AppConfig.baseURL)\(logoPath)") else {
            isLoading = false
            return
        }
        
        // Check cache first
        let cacheKey = url.absoluteString
        if let cachedData = await CacheManager.shared.getImage(key: cacheKey) {
            await MainActor.run {
                self.logoData = cachedData
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
                    self.logoData = data
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
