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

    var isEmailValid: Bool {
        Validators.isValidEmail(email)
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
            if let obj = try? JSONSerialization.jsonObject(with: data) {
                print("Server response:", obj)
            }
        } catch {
            print("Google request failed:", error)
        }
    }
}
