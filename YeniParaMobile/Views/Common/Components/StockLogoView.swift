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
            // Use actual IP for device, localhost for simulator
            #if targetEnvironment(simulator)
            let baseURL = "http://localhost:4000"
            #else
            let baseURL = "http://192.168.1.210:4000"
            #endif
            
            guard let url = URL(string: "\(baseURL)/api/v1/logos/\(symbol).jpeg") else {
                await MainActor.run {
                    self.isLoading = false
                }
                return
            }
            
            var request = URLRequest(url: url)
            
            // Add auth token if available
            if let token = authToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                // Check if we got image data
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200,
                   UIImage(data: data) != nil {
                    await MainActor.run {
                        self.imageData = data
                        self.isLoading = false
                    }
                } else {
                    print("Invalid image data for \(symbol)")
                    await MainActor.run {
                        self.isLoading = false
                    }
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