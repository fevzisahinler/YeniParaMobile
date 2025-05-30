import Foundation
import Combine
import SwiftUI
import GoogleSignIn
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
    
    @Published var googleProfileIncompleteUserID: Int?
    @Published var showPhoneNumberEntry: Bool = false
    @Published var showRegisterComplete: Bool = false
    @Published var isLoggedIn: Bool = false
    @Published var accessToken: String? = nil
    @Published var refreshToken: String? = nil
    
    // Quiz related properties
    @Published var isQuizCompleted: Bool = false
    @Published var shouldShowQuiz: Bool = false
    
    private let keychainHelper = KeychainHelper.shared
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    
    var isEmailValid: Bool {
        Validators.isValidEmail(email)
    }
    
    override init() {
        super.init()
        checkStoredTokens()
    }
    
    // MARK: - Token Management
    private func checkStoredTokens() {
        if let storedAccessToken = getStoredAccessToken(),
           let storedRefreshToken = getStoredRefreshToken() {
            self.accessToken = storedAccessToken
            self.refreshToken = storedRefreshToken
            
            // Token'ları doğrula veya refresh et
            Task {
                await validateOrRefreshTokens()
            }
        }
    }
    
    private func saveTokens(accessToken: String, refreshToken: String) {
        // Access token'ı kaydet
        if let accessData = accessToken.data(using: .utf8) {
            keychainHelper.save(accessData, service: "YeniParaApp", account: accessTokenKey)
        }
        
        // Refresh token'ı kaydet
        if let refreshData = refreshToken.data(using: .utf8) {
            keychainHelper.save(refreshData, service: "YeniParaApp", account: refreshTokenKey)
        }
        
        self.accessToken = accessToken
        self.refreshToken = refreshToken
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
        self.accessToken = nil
        self.refreshToken = nil
    }
    
    private func validateOrRefreshTokens() async {
        // Eğer access token varsa doğrula
        guard let currentRefreshToken = refreshToken else {
            logout()
            return
        }
        
        // Access token'ı refresh et
        let success = await refreshAccessToken(refreshToken: currentRefreshToken)
        if success {
            // Quiz durumunu kontrol et
            await checkQuizStatus()
            self.isLoggedIn = true
        } else {
            logout()
        }
    }
    
    func refreshAccessToken(refreshToken: String) async -> Bool {
        guard let url = URL(string: "http://localhost:4000/api/v1//refresh") else { return false }
        
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
                    
                    // Yeni access token'ı kaydet (refresh token aynı kalabilir)
                    if let accessData = newAccessToken.data(using: .utf8) {
                        keychainHelper.save(accessData, service: "YeniParaApp", account: accessTokenKey)
                    }
                    self.accessToken = newAccessToken
                    
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
        guard let url = URL(string: "http://localhost:4000/api/v1/quiz/status") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return }
            
            if httpResponse.statusCode == 401 {
                // Token expired, try to refresh
                if let refreshToken = refreshToken {
                    let refreshSuccess = await refreshAccessToken(refreshToken: refreshToken)
                    if refreshSuccess {
                        // Retry with new token
                        if let newToken = accessToken {
                            request.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                        }
                        let (newData, newResponse) = try await URLSession.shared.data(for: request)
                        guard let newHttpResponse = newResponse as? HTTPURLResponse,
                              newHttpResponse.statusCode == 200 else { return }
                        
                        if let json = try? JSONSerialization.jsonObject(with: newData) as? [String: Any],
                           let success = json["success"] as? Bool, success,
                           let dataObj = json["data"] as? [String: Any],
                           let quizCompleted = dataObj["quiz_completed"] as? Bool {
                            
                            await MainActor.run {
                                self.isQuizCompleted = quizCompleted
                            }
                        }
                    } else {
                        logout()
                    }
                }
            } else if httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success,
                   let dataObj = json["data"] as? [String: Any],
                   let quizCompleted = dataObj["quiz_completed"] as? Bool {
                    
                    await MainActor.run {
                        self.isQuizCompleted = quizCompleted
                    }
                }
            }
        } catch {
            print("Quiz status check error: \(error)")
        }
    }
    
    // MARK: - Authentication Methods
    func registerUser() async {
        guard let url = URL(string: "http://localhost:4000/api/v1/auth/register") else {
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
        guard let url = URL(string: "http://localhost:4000/api/v1/auth/login") else {
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
                    
                    // User bilgilerini al
                    var quizCompleted = false
                    if let user = dataObj["user"] as? [String: Any],
                       let isQuizCompleted = user["is_quiz_completed"] as? Bool {
                        quizCompleted = isQuizCompleted
                    }
                    
                    await MainActor.run {
                        // Token'ları kaydet
                        saveTokens(accessToken: loginAccessToken, refreshToken: loginRefreshToken)
                        
                        // Quiz completion durumunu kaydet
                        self.isQuizCompleted = quizCompleted
                        
                        // Giriş başarılı
                        isLoading = false
                        emailError = nil
                        isLoggedIn = true
                        
                        print("Login successful!")
                        print("Quiz completed: \(quizCompleted)")
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
              let url = URL(string: "http://localhost:4000/api/v1/auth/resend-otp") else { return }
        
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
              let url = URL(string: "http://localhost:4000/api/v1/auth/verify-email") else {
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
    
    func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController
        else { return }

        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "CLIENT_ID") as? String else {
            fatalError("CLIENT_ID missing in Info.plist")
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
            guard error == nil,
                  let user = result?.user,
                  let tokenString = user.idToken?.tokenString
            else {
                if let error = error {
                    print("Google Sign-In error: \(error.localizedDescription)")
                }
                return
            }
            
            Task { await self.sendGoogleToken(tokenString) }
        }
    }
    
    private func sendGoogleToken(_ idToken: String) async {
        guard let url = URL(string: "http://localhost:4000/api/v1/auth/google") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["id_token": idToken]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResp = response as? HTTPURLResponse {
                print("Google response status: \(httpResp.statusCode)")
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("Server response:", json)
                
                if let successValue = json["success"] as? Bool, successValue,
                   let dataObj = json["data"] as? [String: Any] {
                    
                    guard let googleAccessToken = dataObj["access_token"] as? String,
                          let googleRefreshToken = dataObj["refresh_token"] as? String else { return }
                    
                    // Quiz completion durumunu kontrol et
                    var quizCompleted = false
                    if let user = dataObj["user"] as? [String: Any],
                       let isQuizCompleted = user["is_quiz_completed"] as? Bool {
                        quizCompleted = isQuizCompleted
                    }
                    
                    await MainActor.run {
                        // Token'ları kaydet ve giriş yap
                        saveTokens(accessToken: googleAccessToken, refreshToken: googleRefreshToken)
                        self.isQuizCompleted = quizCompleted
                        isLoggedIn = true
                        print("Google login successful!")
                        print("Quiz completed: \(quizCompleted)")
                    }
                }
                else if let successValue = json["success"] as? Int, successValue == 0,
                        let errorMessage = json["error"] as? String,
                        errorMessage == "User incomplete, please complete your profile",
                        let userID = json["user_id"] as? Int {
                    await MainActor.run {
                        self.googleProfileIncompleteUserID = userID
                        self.showPhoneNumberEntry = true
                    }
                }
            }
        } catch {
            print("Google request failed:", error)
        }
    }
    
    func completeProfile(userID: Int, phoneNumber: String) async -> Bool {
        guard let url = URL(string: "http://localhost:4000/api/v1/auth/complete-profile") else {
            return false
        }
        let requestBody: [String: Any] = [
            "user_id": userID,
            "phone_number": phoneNumber
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResp = response as? HTTPURLResponse else { return false }
            print("completeProfile status code:", httpResp.statusCode)
            
            if httpResp.statusCode == 200 || httpResp.statusCode == 201 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success == true {
                    return true
                }
            } else {
                print("completeProfile failed with code \(httpResp.statusCode)")
            }
        } catch {
            print("completeProfile error:", error)
        }
        return false
    }
    
    // MARK: - Utility Methods
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
