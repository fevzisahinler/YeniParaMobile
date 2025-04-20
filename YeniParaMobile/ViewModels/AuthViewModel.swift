import Foundation
import Combine

final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var showRegister: Bool = false
    
    var isEmailValid: Bool {
        Validators.isValidEmail(email)
    }
    
    func login() {
        print("Login with:", email)
    }
    
    func signInWithGoogle() {
        print("Google Sign‑In")
    }
    
    func signInWithApple() {
        print("Apple Sign‑In")
    }
    
    func register() {
        showRegister = true
    }
}
