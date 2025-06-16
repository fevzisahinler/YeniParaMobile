import Foundation

@MainActor
final class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL: String
    private var authViewModel: AuthViewModel?
    private let session: URLSession
    
    private init() {
        // Use production URL when not in debug mode
        #if DEBUG
        self.baseURL = "http://192.168.1.210:4000"
        #else
        self.baseURL = "https://api.yenipara.com" // Replace with your production URL
        #endif
        
        // Configure URLSession with timeout
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        self.session = URLSession(configuration: configuration)
    }
    
    func setAuthViewModel(_ authVM: AuthViewModel) {
        self.authViewModel = authVM
    }
    
    // MARK: - Network Reachability
    private func isNetworkAvailable() -> Bool {
        return NetworkMonitor.shared.isConnected
    }
    
    // MARK: - Generic API Request Method with Retry Logic
    func makeRequest<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: [String: Any]? = nil,
        responseType: T.Type,
        requiresAuth: Bool = true,
        retryCount: Int = 3
    ) async throws -> T {
        
        guard isNetworkAvailable() else {
            throw APIError.networkError
        }
        
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var currentRetry = 0
        var lastError: Error = APIError.networkError
        
        while currentRetry < retryCount {
            do {
                return try await performRequest(
                    url: url,
                    method: method,
                    body: body,
                    responseType: responseType,
                    requiresAuth: requiresAuth
                )
            } catch {
                lastError = error
                currentRetry += 1
                
                // Don't retry for client errors (4xx)
                if let apiError = error as? APIError,
                   case .serverError(let code) = apiError,
                   code >= 400 && code < 500 {
                    throw error
                }
                
                // Wait before retry with exponential backoff
                if currentRetry < retryCount {
                    let delay = pow(2.0, Double(currentRetry - 1))
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError
    }
    
    private func performRequest<T: Decodable>(
        url: URL,
        method: HTTPMethod,
        body: [String: Any]?,
        responseType: T.Type,
        requiresAuth: Bool
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("iOS", forHTTPHeaderField: "X-Platform")
        request.setValue(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                        forHTTPHeaderField: "X-App-Version")
        
        // Authorization header
        if requiresAuth, let authVM = authViewModel, let token = authVM.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Body
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        

        
        // Handle 401 - Token refresh
        if httpResponse.statusCode == 401 && requiresAuth {
            if let authVM = authViewModel, let refreshToken = authVM.refreshToken {
                let refreshSuccess = await authVM.refreshAccessToken(refreshToken: refreshToken)
                if refreshSuccess {
                    // Retry with new token
                    if let newToken = authVM.accessToken {
                        request.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                    }
                    let (newData, newResponse) = try await session.data(for: request)
                    
                    guard let newHttpResponse = newResponse as? HTTPURLResponse else {
                        throw APIError.invalidResponse
                    }
                    
                    if newHttpResponse.statusCode >= 200 && newHttpResponse.statusCode < 300 {
                        return try JSONDecoder().decode(T.self, from: newData)
                    } else {
                        throw APIError.serverError(newHttpResponse.statusCode)
                    }
                } else {
                    // Refresh failed, logout
                    authViewModel?.logout()
                    throw APIError.unauthorized
                }
            } else {
                throw APIError.unauthorized
            }
        }
        
        // Success
        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                #if DEBUG
                print("Decoding error: \(error)")
                #endif
                throw APIError.decodingError
            }
        } else {
            // Try to decode error message
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverErrorWithMessage(httpResponse.statusCode, errorResponse.error ?? "Unknown error")
            }
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Authentication API Methods
    
    // Register new user
    func registerUser(email: String, password: String, username: String, fullName: String, phoneNumber: String) async throws -> AuthResponse {
        return try await makeRequest(
            endpoint: "/api/v1/auth/register",
            method: .POST,
            body: [
                "email": email,
                "password": password,
                "username": username,
                "full_name": fullName,
                "phone_number": phoneNumber
            ],
            responseType: AuthResponse.self,
            requiresAuth: false
        )
    }
    
    // Verify email
    func verifyEmail(userId: Int, code: String) async throws -> MessageResponse {
        return try await makeRequest(
            endpoint: "/api/v1/auth/verify-email",
            method: .POST,
            body: [
                "user_id": userId,
                "code": code
            ],
            responseType: MessageResponse.self,
            requiresAuth: false
        )
    }
    
    // Resend OTP
    func resendOTP(userId: Int) async throws -> MessageResponse {
        return try await makeRequest(
            endpoint: "/api/v1/auth/resend-otp",
            method: .POST,
            body: ["user_id": userId],
            responseType: MessageResponse.self,
            requiresAuth: false
        )
    }
    
    // MARK: - Quiz API Methods
    
    // Get quiz questions - Public endpoint
    func getQuizQuestions() async throws -> QuizQuestionsResponse {
        return try await makeRequest(
            endpoint: "/api/v1/quiz/questions",
            responseType: QuizQuestionsResponse.self,
            requiresAuth: false
        )
    }
    
    // Submit quiz answers - Protected
    func submitQuizAnswers(answers: [String: Int]) async throws -> QuizSubmitResponse {
        return try await makeRequest(
            endpoint: "/api/v1/quiz/submit",
            method: .POST,
            body: ["answers": answers],
            responseType: QuizSubmitResponse.self,
            requiresAuth: true
        )
    }
    
    // Get quiz status - Protected
    func getQuizStatus() async throws -> QuizStatusResponse {
        return try await makeRequest(
            endpoint: "/api/v1/quiz/status",
            responseType: QuizStatusResponse.self,
            requiresAuth: true
        )
    }
    
    // MARK: - Market Data API Methods (All Protected)
    
    // Get symbols list - Protected
    func getSymbols(page: Int = 1, limit: Int = 100, sort: String = "code", order: String = "asc") async throws -> HomeSymbolsAPIResponse {
        return try await makeRequest(
            endpoint: "/api/v1/symbols?page=\(page)&limit=\(limit)&sort=\(sort)&order=\(order)",
            responseType: HomeSymbolsAPIResponse.self,
            requiresAuth: true
        )
    }
    
    // Get fundamental data - Protected
    func getFundamentalData(symbol: String) async throws -> DetailFundamentalAPIResponse {
        return try await makeRequest(
            endpoint: "/api/v1/fundamental/\(symbol)",
            responseType: DetailFundamentalAPIResponse.self,
            requiresAuth: true
        )
    }
    
    // Get candle data - Protected
    func getCandleData(symbol: String, timeframe: String, from: String? = nil, to: String? = nil) async throws -> DetailCandleAPIResponse {
        var queryParams = "symbol=\(symbol)&timeframe=\(timeframe)"
        if let from = from {
            queryParams += "&from=\(from)"
        }
        if let to = to {
            queryParams += "&to=\(to)"
        }
        
        return try await makeRequest(
            endpoint: "/api/v1/market/candles?\(queryParams)",
            responseType: DetailCandleAPIResponse.self,
            requiresAuth: true
        )
    }
    
    // Get company logo - Protected
    func getCompanyLogo(symbol: String) async throws -> Data {
        guard isNetworkAvailable() else {
            throw APIError.networkError
        }
        
        guard let url = URL(string: "\(baseURL)/api/v1/logos/\(symbol).jpeg") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("iOS", forHTTPHeaderField: "X-Platform")
        
        // Add authorization header
        if let authVM = authViewModel, let token = authVM.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return data
    }
    
    // Clear cache on logout
    func clearCache() {
        // Clear any cached data
    }
}

// MARK: - HTTP Method Enum
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

// MARK: - Enhanced API Error Types
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(Int)
    case serverErrorWithMessage(Int, String)
    case decodingError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Geçersiz URL"
        case .invalidResponse:
            return "Geçersiz sunucu yanıtı"
        case .unauthorized:
            return "Oturumunuz sonlanmış. Lütfen tekrar giriş yapın."
        case .serverError(let code):
            return "Sunucu hatası: \(code)"
        case .serverErrorWithMessage(_, let message):
            return message
        case .decodingError:
            return "Veri işleme hatası"
        case .networkError:
            return "İnternet bağlantınızı kontrol edin"
        }
    }
}

// MARK: - Error Response Model
struct ErrorResponse: Codable {
    let error: String?
    let message: String?
    let success: Bool?
}

// MARK: - Message Response
struct MessageResponse: Codable {
    let message: String
    let success: Bool
}
