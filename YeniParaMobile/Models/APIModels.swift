import Foundation

// MARK: - API Response Models
struct SymbolsResponse: Decodable {
    let data: [String]
    let success: Bool
}

struct HistoricalResponse: Decodable {
    let data: [CandleAPIModel]
}

struct CandleAPIModel: Decodable {
    let timestamp: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
}

struct CandleData: Identifiable {
    let id = UUID()
    let timestamp: Date
    let open, high, low, close, volume: Double
}

// MARK: - Auth Models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let username: String
    let full_name: String
    let phone_number: String
}

struct AuthResponse: Codable {
    let success: Int
    let data: AuthData?
    let error: String?
    let user_id: Int?
}

struct AuthData: Codable {
    let user_id: Int
    let access_token: String?
    let refresh_token: String?
}
