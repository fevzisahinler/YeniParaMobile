import SwiftUI

struct AuthorizedAsyncImage: View {
    let photoPath: String?
    let size: CGFloat
    let fallbackText: String
    
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if isLoading {
                Circle()
                    .fill(AppColors.primary.opacity(0.2))
                    .frame(width: size, height: size)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.5)
                    )
            } else {
                // Fallback
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary.opacity(0.3), AppColors.secondary.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .overlay(
                        Text(fallbackText.prefix(1).uppercased())
                            .font(.system(size: size * 0.4, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let photoPath = photoPath, !photoPath.isEmpty else {
            isLoading = false
            return
        }
        
        // Create full URL
        let fullURL = photoPath.starts(with: "http") ? photoPath : "http://192.168.1.210:4000\(photoPath)"
        
        guard let url = URL(string: fullURL) else {
            isLoading = false
            return
        }
        
        // Get token
        guard let token = KeychainHelper.shared.getToken(type: .access) else {
            isLoading = false
            return
        }
        
        Task {
            do {
                var request = URLRequest(url: url)
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                
                let (data, _) = try await URLSession.shared.data(for: request)
                
                if let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        self.image = uiImage
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            } catch {
                print("Error loading image: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}