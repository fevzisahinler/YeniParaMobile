import SwiftUI

struct ProfileImageView: View {
    let photoPath: String?
    let size: CGFloat
    let fallbackIcon: String?
    let fallbackText: String
    
    @State private var imageData: Data?
    @State private var isLoading = true
    
    init(photoPath: String?, size: CGFloat = 100, fallbackIcon: String? = nil, fallbackText: String = "U") {
        self.photoPath = photoPath
        self.size = size
        self.fallbackIcon = fallbackIcon
        self.fallbackText = fallbackText
    }
    
    var body: some View {
        Group {
            if let imageData = imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if isLoading && photoPath != nil {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                    .frame(width: size, height: size)
            } else {
                // Fallback view
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .overlay(
                        Group {
                            if let icon = fallbackIcon {
                                Text(icon)
                                    .font(.system(size: size * 0.5))
                            } else {
                                Text(fallbackText)
                                    .font(.system(size: size * 0.42, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    )
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: photoPath) { _ in
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let photoPath = photoPath else {
            isLoading = false
            return
        }
        
        Task {
            do {
                if let data = try await APIService.shared.getProfilePhotoData(photoPath: photoPath) {
                    await MainActor.run {
                        self.imageData = data
                        self.isLoading = false
                    }
                }
            } catch {
                print("Error loading profile photo: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

struct ProfileImageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ProfileImageView(photoPath: nil)
            ProfileImageView(photoPath: "/api/v1/user/photo/test.jpg")
        }
        .preferredColorScheme(.dark)
    }
}