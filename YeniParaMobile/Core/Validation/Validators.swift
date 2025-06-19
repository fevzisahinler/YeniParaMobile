import Foundation

enum Validators {
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }
    
    static func isValidPassword(_ password: String) -> Bool {
        // En az 8 karakter
        guard password.count >= 8 else { return false }
        
        // En az 1 büyük harf
        let uppercaseRegex = ".*[A-Z]+.*"
        guard NSPredicate(format: "SELF MATCHES %@", uppercaseRegex).evaluate(with: password) else {
            return false
        }
        
        // En az 1 rakam
        let digitRegex = ".*[0-9]+.*"
        guard NSPredicate(format: "SELF MATCHES %@", digitRegex).evaluate(with: password) else {
            return false
        }
        
        return true
    }
    
    static func isValidPhoneNumber(_ phone: String) -> Bool {
        let digits = phone.filter(\.isNumber)
        return digits.count == 10 || digits.count == 11
    }
    
    static func isValidUsername(_ username: String) -> Bool {
        // 3-20 karakter, alfanumerik ve _ . izinli
        let usernameRegex = "^[a-zA-Z0-9_.]{3,20}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        return predicate.evaluate(with: username)
    }
}
