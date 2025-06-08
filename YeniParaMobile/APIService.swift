import Foundation

@MainActor
final class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL = "http://192.168.1.210:4000"
    private var authViewModel: AuthViewModel?
    
    private init() {}
    
    func setAuthViewModel(_ authVM: AuthViewModel) {
        self.authViewModel = authVM
    }
    
    // MARK: - Generic API Request Method
    func makeRequest<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: [String: Any]? = nil,
        responseType: T.Type,
        requiresAuth: Bool = true
    ) async throws -> T {
        
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Authorization header ekle
        if requiresAuth, let authVM = authViewModel, let token = authVM.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Body varsa ekle
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // 401 durumunda token refresh
        if httpResponse.statusCode == 401 && requiresAuth {
            if let authVM = authViewModel, let refreshToken = authVM.refreshToken {
                let refreshSuccess = await authVM.refreshAccessToken(refreshToken: refreshToken)
                if refreshSuccess {
                    // Token refresh başarılı, isteği tekrar yap
                    if let newToken = authVM.accessToken {
                        request.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                    }
                    let (newData, newResponse) = try await URLSession.shared.data(for: request)
                    
                    guard let newHttpResponse = newResponse as? HTTPURLResponse else {
                        throw APIError.invalidResponse
                    }
                    
                    if newHttpResponse.statusCode >= 200 && newHttpResponse.statusCode < 300 {
                        return try JSONDecoder().decode(T.self, from: newData)
                    } else {
                        throw APIError.serverError(newHttpResponse.statusCode)
                    }
                } else {
                    // Refresh başarısız, logout
                    authViewModel?.logout()
                    throw APIError.unauthorized
                }
            } else {
                throw APIError.unauthorized
            }
        }
        
        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
            return try JSONDecoder().decode(T.self, from: data)
        } else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Specific API Methods
    
    // Kullanıcı profili al
    func getUserProfile() async throws -> UserProfile {
        return try await makeRequest(
            endpoint: "/user/profile",
            responseType: UserProfile.self
        )
    }
    
    // Hisse listesi al
    func getStocks() async throws -> StocksResponse {
        return try await makeRequest(
            endpoint: "/stocks",
            responseType: StocksResponse.self,
            requiresAuth: false
        )
    }
    
    // Belirli bir hisse detayı al
    func getStockDetail(symbol: String) async throws -> StockDetail {
        return try await makeRequest(
            endpoint: "/stocks/\(symbol)",
            responseType: StockDetail.self,
            requiresAuth: false
        )
    }
    
    // Hisse fiyat geçmişi al
    func getStockHistory(symbol: String, period: String = "1d") async throws -> StockHistoryResponse {
        return try await makeRequest(
            endpoint: "/stocks/\(symbol)/history?period=\(period)",
            responseType: StockHistoryResponse.self,
            requiresAuth: false
        )
    }
    
    // Watchlist'e hisse ekle
    func addToWatchlist(symbol: String) async throws -> MessageResponse {
        return try await makeRequest(
            endpoint: "/user/watchlist",
            method: .POST,
            body: ["symbol": symbol],
            responseType: MessageResponse.self
        )
    }
    
    // Watchlist'ten hisse çıkar
    func removeFromWatchlist(symbol: String) async throws -> MessageResponse {
        return try await makeRequest(
            endpoint: "/user/watchlist/\(symbol)",
            method: .DELETE,
            responseType: MessageResponse.self
        )
    }
    
    // Kullanıcının watchlist'ini al
    func getWatchlist() async throws -> WatchlistResponse {
        return try await makeRequest(
            endpoint: "/user/watchlist",
            responseType: WatchlistResponse.self
        )
    }
}

// MARK: - HTTP Method Enum
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

// MARK: - API Error Types
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(Int)
    case decodingError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Geçersiz URL"
        case .invalidResponse:
            return "Geçersiz sunucu yanıtı"
        case .unauthorized:
            return "Yetkilendirme hatası"
        case .serverError(let code):
            return "Sunucu hatası: \(code)"
        case .decodingError:
            return "Veri işleme hatası"
        case .networkError:
            return "Ağ bağlantısı hatası"
        }
    }
}

// MARK: - API Response Models
struct UserProfile: Codable {
    let id: Int
    let email: String
    let fullName: String
    let username: String
    let phoneNumber: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, email, username
        case fullName = "full_name"
        case phoneNumber = "phone_number"
        case createdAt = "created_at"
    }
}

struct StocksResponse: Codable {
    let data: [StockData]
    let success: Bool
}

struct StockData: Codable, Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let price: Double
    let change: Double
    let changePercent: Double
    let volume: String
    let marketCap: String
    
    enum CodingKeys: String, CodingKey {
        case symbol, name, price, change, volume
        case changePercent = "change_percent"
        case marketCap = "market_cap"
    }
}

struct StockDetail: Codable {
    let symbol: String
    let name: String
    let price: Double
    let change: Double
    let changePercent: Double
    let volume: String
    let marketCap: String
    let openPrice: Double
    let high24h: Double
    let low24h: Double
    let beta: Double?
    let peRatio: Double?
    
    enum CodingKeys: String, CodingKey {
        case symbol, name, price, change, volume, beta
        case changePercent = "change_percent"
        case marketCap = "market_cap"
        case openPrice = "open_price"
        case high24h = "high_24h"
        case low24h = "low_24h"
        case peRatio = "pe_ratio"
    }
}

struct StockHistoryResponse: Codable {
    let data: [HistoricalData]
    let success: Bool
}

struct HistoricalData: Codable, Identifiable {
    let id = UUID()
    let timestamp: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
    
    var date: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: timestamp) ?? Date()
    }
}

struct MessageResponse: Codable {
    let message: String
    let success: Bool
}

struct WatchlistResponse: Codable {
    let data: [String] // Array of symbols
    let success: Bool
}
