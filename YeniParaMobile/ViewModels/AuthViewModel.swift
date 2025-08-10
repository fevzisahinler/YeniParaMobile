import Foundation
import Combine
import SwiftUI
import UIKit
import AuthenticationServices

@MainActor
final class AuthViewModel: NSObject, ObservableObject {

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var showRegister: Bool = false
    @Published var emailError: String? = nil
    @Published var isLoading: Bool = false
    
    @Published var newUserEmail: String = ""
    @Published var newUserFullName: String = ""
    @Published var newUserUsername: String = ""
    @Published var newUserPhoneNumber: String = ""
    @Published var newUserPassword: String = ""
    
    @Published var registeredUserID: Int?
    
    @Published var showRegisterComplete: Bool = false
    @Published var isLoggedIn: Bool = false
    @Published var accessToken: String? = nil
    @Published var refreshToken: String? = nil
    
    // Quiz related properties
    @Published var isQuizCompleted: Bool = false
    @Published var shouldShowQuiz: Bool = false
    
    // User profile properties
    @Published var currentUser: User?
    @Published var investorProfile: InvestorProfile?
    
    // Token expiry tracking
    private var tokenExpiryDate: Date?
    private var tokenRefreshTimer: Timer?
    
    private let keychainHelper = KeychainHelper.shared
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    private let tokenExpiryKey = "token_expiry"
    
    var isEmailValid: Bool {
        Validators.isValidEmail(email)
    }
    
    override init() {
        super.init()
        // Başlangıçta login durumunu false yap, sonra token kontrolü yap
        self.isLoggedIn = false
        checkStoredTokens()
        setupTokenRefreshTimer()
    }
    
    deinit {
        tokenRefreshTimer?.invalidate()
    }
    
    // MARK: - Token Management with Expiry
    private func checkStoredTokens() {
        // Başlangıçta logout durumunda başla
        self.isLoggedIn = false
        
        if let storedAccessToken = getStoredAccessToken(),
           let storedRefreshToken = getStoredRefreshToken() {
            
            // Token'ları geçici olarak sakla ama login yapma
            self.accessToken = storedAccessToken
            self.refreshToken = storedRefreshToken
            
            // Check if token is expired
            if let expiryDate = getStoredTokenExpiry(), Date() < expiryDate {
                self.tokenExpiryDate = expiryDate
                
                // Validate tokens - bu metod içinde isLoggedIn = true yapılacak
                Task {
                    await validateOrRefreshTokens()
                }
            } else {
                // Token expired, try to refresh
                Task {
                    let success = await refreshAccessToken(refreshToken: storedRefreshToken)
                    if success {
                        await checkQuizStatus()
                        await MainActor.run {
                            self.isLoggedIn = true
                        }
                    } else {
                        // Refresh başarısız, token'ları temizle
                        await MainActor.run {
                            self.clearStoredTokens()
                        }
                    }
                }
            }
        }
    }
    
    private func setupTokenRefreshTimer() {
        tokenRefreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                self.checkAndRefreshTokenIfNeeded()
            }
        }
    }
    
    private func checkAndRefreshTokenIfNeeded() {
        guard let expiryDate = tokenExpiryDate,
              let refreshToken = refreshToken else { return }
        
        // Refresh token 5 minutes before expiry
        let refreshTime = expiryDate.addingTimeInterval(-300)
        
        if Date() >= refreshTime {
            Task {
                await refreshAccessToken(refreshToken: refreshToken)
            }
        }
    }
    
    // Updated saveTokens method without expiresIn parameter
    func saveTokens(accessToken: String, refreshToken: String) {
        // Save access token
        if let accessData = accessToken.data(using: .utf8) {
            keychainHelper.save(accessData, service: "YeniParaApp", account: accessTokenKey)
        }
        
        // Save refresh token
        if let refreshData = refreshToken.data(using: .utf8) {
            keychainHelper.save(refreshData, service: "YeniParaApp", account: refreshTokenKey)
        }
        
        // Calculate and save expiry date (default 15 minutes)
        let expiryDate = Date().addingTimeInterval(900) // 15 minutes
        if let expiryData = try? JSONEncoder().encode(expiryDate) {
            keychainHelper.save(expiryData, service: "YeniParaApp", account: tokenExpiryKey)
        }
        
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenExpiryDate = expiryDate
    }
    
    private func getStoredTokenExpiry() -> Date? {
        guard let data = keychainHelper.read(service: "YeniParaApp", account: tokenExpiryKey),
              let date = try? JSONDecoder().decode(Date.self, from: data) else { return nil }
        return date
    }
    
    private func getStoredAccessToken() -> String? {
        guard let data = keychainHelper.read(service: "YeniParaApp", account: accessTokenKey) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private func getStoredRefreshToken() -> String? {
        guard let data = keychainHelper.read(service: "YeniParaApp", account: refreshTokenKey) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private func clearStoredTokens() {
        keychainHelper.delete(service: "YeniParaApp", account: accessTokenKey)
        keychainHelper.delete(service: "YeniParaApp", account: refreshTokenKey)
        keychainHelper.delete(service: "YeniParaApp", account: tokenExpiryKey)
        self.accessToken = nil
        self.refreshToken = nil
        self.tokenExpiryDate = nil
        
        // Clear API cache
        APIService.shared.clearCache()
    }
    
    private func validateOrRefreshTokens() async {
        guard let currentRefreshToken = refreshToken else {
            await MainActor.run {
                logout()
            }
            return
        }
        
        // Try to get user profile to validate token
        do {
            // Token is valid, check quiz status
            await checkQuizStatus()
            await MainActor.run {
                self.isLoggedIn = true
            }
        } catch {
            // Token might be invalid, try to refresh
            let success = await refreshAccessToken(refreshToken: currentRefreshToken)
            if success {
                await checkQuizStatus()
                await MainActor.run {
                    self.isLoggedIn = true
                }
            } else {
                // Token geçersiz veya refresh başarısız, logout yap
                await MainActor.run {
                    logout()
                }
            }
        }
    }
    
    func refreshAccessToken(refreshToken: String) async -> Bool {
        // Use production URL when not in debug mode
        #if DEBUG
        let baseURL = "http://192.168.1.210:4000/api/v1"
        #else
        let baseURL = "https://192.168.1.210:4000/api/v1" // Replace with your production URL
        #endif
        
        guard let url = URL(string: "\(baseURL)/auth/refresh") else { return false }
        
        let requestBody: [String: Any] = [
            "refresh_token": refreshToken
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return false }
            
            if httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success,
                   let dataObj = json["data"] as? [String: Any],
                   let newAccessToken = dataObj["access_token"] as? String {
                    
                    // Save new tokens
                    saveTokens(accessToken: newAccessToken, refreshToken: refreshToken)
                    
                    print("Access token refreshed successfully")
                    return true
                }
            }
        } catch {
            print("Refresh token error: \(error)")
        }
        
        return false
    }
    
    // MARK: - Quiz Functions
    func checkQuizStatus() async {
        do {
            let response = try await APIService.shared.getQuizStatus()
            
            if response.success {
                await MainActor.run {
                    self.isQuizCompleted = response.data.quizCompleted
                    self.investorProfile = response.data.investorProfile
                }
            }
        } catch {
            print("Quiz status check error: \(error)")
            
            // If unauthorized, user might need to login again
            if case APIError.unauthorized = error {
                await MainActor.run {
                    self.logout()
                }
            }
        }
    }
    
    // MARK: - Authentication Methods
    func registerUser() async {
        guard let url = URL(string: "http://192.168.1.210:4000/api/v1/auth/register") else {
            await MainActor.run {
                self.emailError = "Geçersiz URL"
            }
            return
        }
        
        let requestBody: [String: Any] = [
            "email": newUserEmail,
            "password": newUserPassword,
            "username": newUserUsername,
            "full_name": newUserFullName,
            "phone_number": newUserPhoneNumber
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        await MainActor.run {
            isLoading = true
            registeredUserID = nil // Reset previous registration ID
            emailError = nil // Clear previous errors
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResp = response as? HTTPURLResponse else {
                await MainActor.run {
                    isLoading = false
                    emailError = "Geçersiz sunucu yanıtı"
                }
                return
            }
            
            print("Register status code:", httpResp.statusCode)
            print("Register response data:", String(data: data, encoding: .utf8) ?? "No data")
            
            if httpResp.statusCode == 200 || httpResp.statusCode == 201 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("Register JSON response:", json)
                    
                    if let success = json["success"] as? Bool, success == true,
                       let dataObj = json["data"] as? [String: Any],
                       let userID = dataObj["user_id"] as? Int {
                        
                        await MainActor.run {
                            self.registeredUserID = userID
                            isLoading = false
                            emailError = nil
                        }
                        print("Registration successful! User ID:", userID)
                    } else {
                        await MainActor.run {
                            isLoading = false
                            emailError = "Kayıt yanıtı işlenemedi"
                        }
                        print("Failed to parse success response")
                    }
                } else {
                    await MainActor.run {
                        isLoading = false
                        emailError = "Yanıt işlenemedi"
                    }
                }
            } else {
                // Handle error response
                var errorMsg = "Kayıt işlemi başarısız"
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? String {
                    errorMsg = error
                    print("Registration failed with error:", error)
                } else {
                    print("Registration failed with status code:", httpResp.statusCode)
                }
                
                await MainActor.run {
                    isLoading = false
                    emailError = errorMsg
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
                emailError = "Ağ bağlantısı hatası: \(error.localizedDescription)"
            }
            print("Register request error:", error)
        }
    }
    
    func login() {
        emailError = nil
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            emailError = "E-posta boş bırakılamaz."
            return
        }
        guard isEmailValid else {
            emailError = "Lütfen geçerli bir e-posta formatı girin."
            return
        }
        guard !password.trimmingCharacters(in: .whitespaces).isEmpty else {
            emailError = "Şifre boş bırakılamaz."
            return
        }
        
        isLoading = true
        
        Task {
            await performLogin()
        }
    }
    
    private func performLogin() async {
        guard let url = URL(string: "http://192.168.1.210:4000/api/v1/auth/login") else {
            await MainActor.run {
                isLoading = false
                emailError = "Sunucu bağlantısı hatası."
            }
            return
        }
        
        let requestBody: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    isLoading = false
                    emailError = "Sunucu yanıt hatası."
                }
                return
            }
            
            print("Login status code:", httpResponse.statusCode)
            
            if httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success,
                   let dataObj = json["data"] as? [String: Any] {
                    
                    // Access token ve refresh token al
                    guard let loginAccessToken = dataObj["access_token"] as? String,
                          let loginRefreshToken = dataObj["refresh_token"] as? String else {
                        await MainActor.run {
                            isLoading = false
                            emailError = "Token bilgileri alınamadı."
                        }
                        return
                    }
                    
                    // User bilgilerini al ve parse et
                    var quizCompleted = false
                    var user: User? = nil
                    
                    if let userDict = dataObj["user"] as? [String: Any] {
                        if let isQuizCompleted = userDict["is_quiz_completed"] as? Bool {
                            quizCompleted = isQuizCompleted
                        }
                        
                        // Parse user data manually
                        if let id = userDict["id"] as? Int,
                           let username = userDict["username"] as? String,
                           let fullName = userDict["full_name"] as? String,
                           let email = userDict["email"] as? String {
                            
                            user = User(
                                id: id,
                                username: username,
                                fullName: fullName,
                                email: email,
                                phoneNumber: userDict["phone_number"] as? String,
                                isEmailVerified: userDict["is_email_verified"] as? Bool ?? false,
                                isQuizCompleted: quizCompleted,
                                investorProfileId: userDict["investor_profile_id"] as? Int,
                                createdAt: userDict["created_at"] as? String ?? ""
                            )
                        }
                    }
                    
                    await MainActor.run {
                        // Token'ları kaydet
                        saveTokens(accessToken: loginAccessToken, refreshToken: loginRefreshToken)
                        
                        // User bilgilerini kaydet
                        self.currentUser = user
                        
                        // Quiz completion durumunu kaydet
                        self.isQuizCompleted = quizCompleted
                        
                        // Giriş başarılı
                        isLoading = false
                        emailError = nil
                        isLoggedIn = true
                        
                        print("Login successful!")
                        print("Quiz completed: \(quizCompleted)")
                        
                        // Check quiz status to get investor profile if quiz is completed
                        if quizCompleted {
                            Task {
                                await self.checkQuizStatus()
                            }
                        }
                    }
                } else {
                    await MainActor.run {
                        isLoading = false
                        emailError = "Giriş başarısız. Lütfen bilgilerinizi kontrol edin."
                    }
                }
            } else {
                // Hata durumunu handle et
                var errorMessage = "Giriş başarısız."
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? String {
                    errorMessage = error
                }
                
                await MainActor.run {
                    isLoading = false
                    emailError = errorMessage
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
                emailError = "Ağ bağlantısı hatası. Lütfen tekrar deneyin."
            }
            print("Login request error:", error)
        }
    }
    
    func logout() {
        clearStoredTokens()
        isLoggedIn = false
        isQuizCompleted = false
        email = ""
        password = ""
        emailError = nil
    }
    
    func resendOTP() async {
        guard let userID = registeredUserID,
              let url = URL(string: "http://192.168.1.210:4000/api/v1/auth/resend-otp") else { return }
        
        let requestBody: [String: Any] = [
            "user_id": userID
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print("Resend OTP:", (response as? HTTPURLResponse)?.statusCode ?? 0)
            if let json = try? JSONSerialization.jsonObject(with: data) {
                print("Resend response:", json)
            }
        } catch {
            print("Resend OTP request error:", error)
        }
    }
    
    func verifyEmail(otpCode: String) async -> Bool {
        guard let userID = registeredUserID,
              let url = URL(string: "http://192.168.1.210:4000/api/v1/auth/verify-email") else {
            return false
        }
        let requestBody: [String: Any] = [
            "user_id": userID,
            "code": otpCode
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("Verify status code:", statusCode)
            
            if statusCode == 200 {
                return true
            } else {
                if let json = try? JSONSerialization.jsonObject(with: data) {
                    print("Verify error:", json)
                }
            }
        } catch {
            print("Verify email request error:", error)
        }
        return false
    }
    
    func makeAuthenticatedRequest(to url: URL, method: String = "GET", body: [String: Any]? = nil) async -> (Data?, URLResponse?) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Access token'ı header'a ekle
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Body varsa ekle
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Eğer 401 (Unauthorized) dönerse token'ı refresh etmeye çalış
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                print("Access token expired, attempting to refresh...")
                
                if let refreshToken = refreshToken {
                    let refreshSuccess = await refreshAccessToken(refreshToken: refreshToken)
                    
                    if refreshSuccess {
                        // Token refresh başarılı, isteği tekrar yap
                        if let newToken = accessToken {
                            request.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                        }
                        return try await URLSession.shared.data(for: request)
                    } else {
                        // Refresh token da geçersiz, kullanıcıyı logout yap
                        await MainActor.run {
                            logout()
                        }
                    }
                }
            }
            
            return (data, response)
        } catch {
            print("Authenticated request error: \(error)")
            return (nil, nil)
        }
    }
}
