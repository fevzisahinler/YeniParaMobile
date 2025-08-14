import Foundation
import Combine

class TokenManager: ObservableObject {
    static let shared = TokenManager()
    
    @Published var isAuthenticated = false
    
    private var refreshTimer: Timer?
    private let keychain = KeychainHelper.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        checkAuthStatus()
        setupTokenRefreshTimer()
    }
    
    func saveTokens(accessToken: String, refreshToken: String) {
        _ = keychain.saveAccessToken(accessToken)
        _ = keychain.saveRefreshToken(refreshToken)
        
        UserDefaults.standard.set(Date(), forKey: "tokenSavedDate")
        isAuthenticated = true
        
        setupTokenRefreshTimer()
    }
    
    func getAccessToken() -> String? {
        return keychain.getAccessToken()
    }
    
    func getRefreshToken() -> String? {
        return keychain.getRefreshToken()
    }
    
    func clearTokens() {
        keychain.clearAllTokens()
        UserDefaults.standard.removeObject(forKey: "tokenSavedDate")
        isAuthenticated = false
        refreshTimer?.invalidate()
    }
    
    private func checkAuthStatus() {
        isAuthenticated = keychain.getAccessToken() != nil
    }
    
    private func setupTokenRefreshTimer() {
        refreshTimer?.invalidate()
        
        // Access token'ı 14 dakikada bir yenile (15 dakika expire süresi için)
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 14 * 60, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task {
                await self.refreshAccessToken()
            }
        }
    }
    
    func refreshAccessToken() async {
        guard let refreshToken = getRefreshToken() else {
            // Debug logging removed for production
            await MainActor.run {
                self.clearTokens()
            }
            return
        }
        
        guard let url = URL(string: "\(AppConfig.baseURL)/api/v1/auth/refresh") else {
            // Debug logging removed for production
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                // Debug logging removed for production
                return
            }
            
            if httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let newAccessToken = json["accessToken"] as? String,
                   let newRefreshToken = json["refreshToken"] as? String {
                    
                    await MainActor.run {
                        self.saveTokens(accessToken: newAccessToken, refreshToken: newRefreshToken)
                    }
                    
                    // Debug logging removed for production
                }
            } else if httpResponse.statusCode == 401 {
                // Refresh token expired
                await MainActor.run {
                    self.clearTokens()
                }
                // Debug logging removed for production
            }
        } catch {
            // Debug logging removed for production
        }
    }
    
    func addAuthorizationHeader(to request: inout URLRequest) {
        if let accessToken = getAccessToken() {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
    }
    
    func isTokenExpired() -> Bool {
        guard let savedDate = UserDefaults.standard.object(forKey: "tokenSavedDate") as? Date else {
            return true
        }
        
        let timeElapsed = Date().timeIntervalSince(savedDate)
        return timeElapsed > AppConstants.accessTokenExpiry
    }
    
    func handleUnauthorizedResponse() async {
        await refreshAccessToken()
    }
}