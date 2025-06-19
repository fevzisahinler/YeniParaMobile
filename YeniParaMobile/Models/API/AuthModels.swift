import Foundation

// MARK: - Request Models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let username: String
    let fullName: String
    let phoneNumber: String
    
    enum CodingKeys: String, CodingKey {
        case email, password, username
        case fullName = "full_name"
        case phoneNumber = "phone_number"
    }
}

// MARK: - Response Models
struct AuthResponse: Codable {
    let success: Bool
    let data: AuthData?
    let error: String?
    let userId: Int?
    
    enum CodingKeys: String, CodingKey {
        case success, data, error
        case userId = "user_id"
    }
}

struct AuthData: Codable {
    let userId: Int
    let accessToken: String?
    let refreshToken: String?
    let user: User?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

struct User: Codable {
    let id: Int
    let email: String
    let username: String
    let fullName: String
    let phoneNumber: String
    let isQuizCompleted: Bool
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, email, username
        case fullName = "full_name"
        case phoneNumber = "phone_number"
        case isQuizCompleted = "is_quiz_completed"
        case createdAt = "created_at"
    }
}

struct MessageResponse: Codable {
    let message: String
    let success: Bool
}
