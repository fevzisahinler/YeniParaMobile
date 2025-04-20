import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var showRegister: Bool = false
    @Published var emailError: String? = nil
    @Published var isLoading: Bool = false

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
                // TODO: AuthService Real API Call
                try await Task.sleep(nanoseconds: 1_000_000_000)
                print("Login başarılı: \(email)")
            } catch {
                emailError = error.localizedDescription
            }
            isLoading = false
        }
    }

    func signInWithGoogle() {
        // TODO
    }

    func signInWithApple() {
        // TODO
    }
}
