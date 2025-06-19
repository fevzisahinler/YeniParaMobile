// Core/Helpers/PasswordValidator.swift
struct PasswordValidator {
    static func validations(for password: String) -> [ValidationItem] {
        [
            ValidationItem(
                title: "En az 8 karakter",
                isValid: password.count >= 8,
                icon: "checkmark.circle.fill"
            ),
            ValidationItem(
                title: "En az 1 büyük harf",
                isValid: password.range(of: "[A-Z]", options: .regularExpression) != nil,
                icon: "checkmark.circle.fill"
            ),
            ValidationItem(
                title: "En az 1 rakam",
                isValid: password.range(of: "[0-9]", options: .regularExpression) != nil,
                icon: "checkmark.circle.fill"
            )
        ]
    }
    
    static func isValid(_ password: String) -> Bool {
        validations(for: password).allSatisfy { $0.isValid }
    }
}
