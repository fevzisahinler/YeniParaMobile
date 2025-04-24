import Foundation
import Combine
import SwiftUI
import GoogleSignIn
import UIKit

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var showRegister: Bool = false
    @Published var emailError: String? = nil
    @Published var isLoading: Bool = false

    @Published var newUserEmail: String = ""
    @Published var newUserFullName: String = ""
    @Published var newUserUsername: String = ""
    @Published var newUserPhoneNumber: String = ""
    @Published var newUserPassword: String = ""

    var isEmailValid: Bool {
        Validators.isValidEmail(email)
    }

    func login() {
        emailError = nil
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            emailError = "E‑posta boş bırakılamaz."
            return
        }
        guard isEmailValid else {
            emailError = "Lütfen geçerli bir e‑posta formatı girin."
            return
        }
        isLoading = true
        Task {
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000)
            } catch {
                emailError = error.localizedDescription
            }
            isLoading = false
        }
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
            //print("ID Token:", tokenString)

            Task {
                guard let url = URL(string: "http://192.168.1.8:4000/auth/google") else { return }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                let body = ["id_token": tokenString]
                request.httpBody = try? JSONSerialization.data(withJSONObject: body)
                do {
                    let (data, response) = try await URLSession.shared.data(for: request)
                    if let httpResp = response as? HTTPURLResponse {
                        print("Google login response status: \(httpResp.statusCode)")
                    }
                    if let obj = try? JSONSerialization.jsonObject(with: data) {
                        print("Server response:", obj)
                    }
                } catch {
                    print("Google login request failed:", error)
                }
            }
        }
    }

    func signInWithApple() {
    }

    func register() async {
        guard let url = URL(string: "http://192.168.1.8:4000/auth/register") else { return }

        let body: [String: String] = [
            "email": newUserEmail,
            "password": newUserPassword,
            "username": newUserUsername,
            "full_name": newUserFullName,
            "phone_number": newUserPhoneNumber
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResp = response as? HTTPURLResponse {
                print("Register response status: \(httpResp.statusCode)")
            }
        } catch {
            print("Register failed: \(error)")
        }
    }
}
