import Foundation

struct Validators {
    static func isValidEmail(_ email: String) -> Bool {
        return email.contains("@") && email.contains(".")
    }
}
