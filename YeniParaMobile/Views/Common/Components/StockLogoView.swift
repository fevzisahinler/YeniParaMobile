import SwiftUI

struct StockLogoView: View {
    let symbol: String
    let size: CGFloat
    let authToken: String?
    
    @State private var imageData: Data?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let imageData = imageData,
               let uiImage = UIImage(data: imageData) {
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
            guard let token = authToken else {
                await MainActor.run {
                    self.isLoading = false
                }
                return
            }
            
            guard let url = URL(string: "http://localhost:4000/api/v1/logos/\(symbol).jpeg") else {
                await MainActor.run {
                    self.isLoading = false
                }
                return
            }
            
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                await MainActor.run {
                    self.imageData = data
                    self.isLoading = false
                }
            } catch {
                print("Error loading logo for \(symbol): \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}