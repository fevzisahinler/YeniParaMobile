import Foundation
import Combine
import SwiftUI
import GoogleSignIn
import UIKit
import AuthenticationServices

@MainActor
final class AuthViewModel: NSObject, ObservableObject {

    @Published var email: String = ""
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
    
    var isEmailValid: Bool {
        Validators.isValidEmail(email)
    }
    
    func registerUser() async {
        guard let url = URL(string: "http://192.168.1.8:4000/auth/register") else { return }
        
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
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResp = response as? HTTPURLResponse else { return }
            print("Register status code:", httpResp.statusCode)
            
            if httpResp.statusCode == 200 || httpResp.statusCode == 201 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataObj = json["data"] as? [String: Any],
                   let userID = dataObj["user_id"] as? Int {
                    self.registeredUserID = userID
                    print("New userID:", userID)
                }
            } else {
                print("Register failed with code \(httpResp.statusCode)")
            }
        } catch {
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
        isLoading = true
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            isLoading = false
        }
    }
    
    func resendOTP() async {
        guard let userID = registeredUserID,
              let url = URL(string: "http://192.168.1.8:4000/auth/resend-otp") else { return }
        
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
              let url = URL(string: "http://192.168.1.8:4000/auth/verify-email") else {
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
        guard let url = URL(string: "http://192.168.1.8:4000/auth/google") else { return }
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
                
                if let successValue = json["success"] as? Int, successValue == 1 {
                }
                else if let successValue = json["success"] as? Int, successValue == 0,
                        let errorMessage = json["error"] as? String,
                        errorMessage == "User incomplete, please complete your profile",
                        let userID = json["user_id"] as? Int {
                    self.googleProfileIncompleteUserID = userID
                    self.showPhoneNumberEntry = true
                }
            }
        } catch {
            print("Google request failed:", error)
        }
    }
    
    func completeProfile(userID: Int, phoneNumber: String) async -> Bool {
        guard let url = URL(string: "http://192.168.1.8:4000/auth/complete-profile") else {
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
}
