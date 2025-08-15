import Foundation

@MainActor
final class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL: String
    private var authViewModel: AuthViewModel?
    private let session: URLSession
    private let cache = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 50 * 1024 * 1024)
    
    private init() {
        // Use production URL when not in debug mode
        #if DEBUG
        self.baseURL = "http://192.168.1.210:4000"
        #else
        self.baseURL = "https://api.yenipara.com" // Replace with your production URL
        #endif
        
        // Configure URLSession with timeout and smart cache
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 30
        configuration.waitsForConnectivity = true
        // Use protocol cache policy - server will control with Cache-Control headers
        configuration.requestCachePolicy = .useProtocolCachePolicy
        configuration.urlCache = cache
        configuration.httpMaximumConnectionsPerHost = 6
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
        
        // For market data endpoints, always get fresh data
        if url.absoluteString.contains("/market/") || 
           url.absoluteString.contains("/symbols") ||
           url.absoluteString.contains("/quote") ||
           url.absoluteString.contains("/snapshot") {
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        }
        
        // Authorization header
        if requiresAuth, let authVM = authViewModel, let token = authVM.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Body
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        // Debug log
        if let jsonString = String(data: data, encoding: .utf8) {
            // Debug logging removed for production
        }
        
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
                // Decoding error logging removed for production
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
    func getCandleData(symbol: String, period: String) async throws -> DetailCandleAPIResponse {
        let queryParams = "symbol=\(symbol)&period=\(period)"
        
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
    
    // MARK: - Stock Comments API Methods
    
    // Get comments for a stock
    func getStockComments(symbol: String, page: Int = 1, limit: Int = 20, sort: String = "latest") async throws -> CommentsListResponse {
        // Debug logging removed for production
        return try await makeRequest(
            endpoint: "/api/v1/stocks/\(symbol)/comments?page=\(page)&limit=\(limit)&sort=\(sort)",
            responseType: CommentsListResponse.self,
            requiresAuth: true
        )
    }
    
    // Create a new comment
    func createStockComment(symbol: String, content: String, sentiment: CommentSentiment, isAnalysis: Bool, parentId: Int? = nil) async throws -> CreateCommentResponse {
        var body: [String: Any] = [
            "content": content,
            "sentiment": sentiment.rawValue,
            "is_analysis": isAnalysis
        ]
        
        if let parentId = parentId {
            body["parent_id"] = parentId
        } else {
            body["parent_id"] = NSNull()
        }
        
        return try await makeRequest(
            endpoint: "/api/v1/stocks/\(symbol)/comments",
            method: .POST,
            body: body,
            responseType: CreateCommentResponse.self,
            requiresAuth: true
        )
    }
    
    // Vote on a comment
    func voteComment(commentId: Int, voteType: VoteType) async throws -> VoteCommentResponse {
        return try await makeRequest(
            endpoint: "/api/v1/stocks/comments/\(commentId)/vote",
            method: .POST,
            body: ["vote_type": voteType.rawValue],
            responseType: VoteCommentResponse.self,
            requiresAuth: true
        )
    }
    
    // Get stock sentiment
    func getStockSentiment(symbol: String, days: Int = 7) async throws -> StockSentimentResponse {
        return try await makeRequest(
            endpoint: "/api/v1/stocks/\(symbol)/sentiment?days=\(days)",
            responseType: StockSentimentResponse.self,
            requiresAuth: true
        )
    }
    
    // Get followed stocks
    func getFollowedStocks() async throws -> FollowedStocksResponse {
        return try await makeRequest(
            endpoint: "/api/v1/stocks/followed",
            responseType: FollowedStocksResponse.self,
            requiresAuth: true
        )
    }
    
    // Get weekly stats for a stock
    func getWeeklyStats(symbol: String) async throws -> WeeklyStatsResponse {
        return try await makeRequest(
            endpoint: "/api/v1/stocks/\(symbol)/weekly-stats",
            responseType: WeeklyStatsResponse.self,
            requiresAuth: true
        )
    }
    
    // Vote on weekly performance
    func voteWeekly(symbol: String, voteType: String, reason: String) async throws -> MessageResponse {
        return try await makeRequest(
            endpoint: "/api/v1/stocks/\(symbol)/vote-weekly",
            method: .POST,
            body: [
                "vote_type": voteType,
                "reason": reason
            ],
            responseType: MessageResponse.self,
            requiresAuth: true
        )
    }
    
    // MARK: - User Profile API Methods
    
    // Get user profile
    func getUserProfile() async throws -> UserProfileResponse {
        return try await makeRequest(
            endpoint: "/api/v1/user/profile",
            responseType: UserProfileResponse.self,
            requiresAuth: true
        )
    
    }
    
    // Get public profile
    func getPublicProfile(username: String) async throws -> PublicProfileResponse {
        guard let encodedUsername = username.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw APIError.invalidURL
        }
        
        // Debug logging removed for production
        
        return try await makeRequest(
            endpoint: "/api/v1/user/public/\(encodedUsername)",
            method: .GET,
            responseType: PublicProfileResponse.self,
            requiresAuth: true
        )
    }
    
    // Update user profile
    func updateUserProfile(fullName: String, phoneNumber: String) async throws -> UpdateProfileResponse {
        return try await makeRequest(
            endpoint: "/api/v1/user/profile",
            method: .PUT,
            body: [
                "full_name": fullName,
                "phone_number": phoneNumber
            ],
            responseType: UpdateProfileResponse.self,
            requiresAuth: true
        )
    }
    
    // Upload profile photo
    func uploadProfilePhoto(imageData: Data) async throws -> UploadPhotoResponse {
        guard let token = authViewModel?.accessToken else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: baseURL + "/api/v1/user/photo") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        var body = Data()
        
        // Add the image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(UploadPhotoResponse.self, from: data)
    }
    
    // Get profile photo URL
    func getProfilePhotoURL(photoPath: String) -> URL? {
        return URL(string: baseURL + photoPath)
    }
    
    // Get profile photo data with authorization
    func getProfilePhotoData(photoPath: String) async throws -> Data? {
        guard let token = authViewModel?.accessToken else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: baseURL + photoPath) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError
        }
        
        if httpResponse.statusCode == 200 {
            return data
        } else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    // Delete profile photo
    func deleteProfilePhoto() async throws -> DeletePhotoResponse {
        return try await makeRequest(
            endpoint: "/api/v1/user/photo",
            method: .DELETE,
            responseType: DeletePhotoResponse.self,
            requiresAuth: true
        )
    }
    
    // Get public user profile
    func getPublicUserProfile(username: String) async throws -> PublicUserProfileResponse {
        return try await makeRequest(
            endpoint: "/api/v1/user/public/\(username)",
            responseType: PublicUserProfileResponse.self,
            requiresAuth: true
        )
    }
    
    // MARK: - Forum API Methods
    
    // Get followed stocks for forum
    func getForumFollowedStocks() async throws -> ForumFollowedStocksResponse {
        return try await makeRequest(
            endpoint: "/api/v1/stocks/followed",
            responseType: ForumFollowedStocksResponse.self,
            requiresAuth: true
        )
    }
    
    // Follow a stock
    func followStock(symbol: String, notifyOnNews: Bool = true, notifyOnComment: Bool = false) async throws -> FollowStockResponse {
        return try await makeRequest(
            endpoint: "/api/v1/stocks/\(symbol)/follow",
            method: .POST,
            body: [
                "notify_on_news": notifyOnNews,
                "notify_on_comment": notifyOnComment
            ],
            responseType: FollowStockResponse.self,
            requiresAuth: true
        )
    }
    
    // Unfollow a stock
    func unfollowStock(symbol: String) async throws -> MessageResponse {
        return try await makeRequest(
            endpoint: "/api/v1/stocks/\(symbol)/follow",
            method: .DELETE,
            responseType: MessageResponse.self,
            requiresAuth: true
        )
    }
    
    // MARK: - Market Data API Methods
    
    // Get all SP100 symbols with prices
    func getSP100Symbols() async throws -> SP100SymbolsResponse {
        return try await makeRequest(
            endpoint: "/api/v1/market/sp100/symbols",
            responseType: SP100SymbolsResponse.self,
            requiresAuth: true
        )
    }
    
    // Get stock quote
    func getStockQuote(symbol: String) async throws -> StockQuoteResponse {
        return try await makeRequest(
            endpoint: "/api/v1/market/sp100/symbols/\(symbol)/quote",
            responseType: StockQuoteResponse.self,
            requiresAuth: true
        )
    }
    
    // Get stock snapshot
    func getStockSnapshot(symbol: String) async throws -> StockSnapshotResponse {
        return try await makeRequest(
            endpoint: "/api/v1/market/sp100/symbols/\(symbol)/snapshot",
            responseType: StockSnapshotResponse.self,
            requiresAuth: true
        )
    }
    
    // Get 1-day bars
    func getDailyBars(symbol: String, days: Int = 100) async throws -> DailyBarsResponse {
        return try await makeRequest(
            endpoint: "/api/v1/market/sp100/symbols/\(symbol)/1d?days=\(days)",
            responseType: DailyBarsResponse.self,
            requiresAuth: true
        )
    }
    
    // Get 1-minute bars
    func getMinuteBars(symbol: String, days: Int = 3) async throws -> MinuteBarsResponse {
        return try await makeRequest(
            endpoint: "/api/v1/market/sp100/symbols/\(symbol)/1m?days=\(days)",
            responseType: MinuteBarsResponse.self,
            requiresAuth: true
        )
    }
    
    // Get chart data based on timeframe
    func getChartData(symbol: String, timeframe: String) async throws -> ChartDataResponse {
        let endpoint: String
        switch timeframe {
        case "1D":
            endpoint = "/api/v1/market/sp100/symbols/\(symbol)/1m?days=1"
        case "1W":
            endpoint = "/api/v1/market/sp100/symbols/\(symbol)/1d?days=7"
        case "1M":
            endpoint = "/api/v1/market/sp100/symbols/\(symbol)/1d?days=30"
        case "3M":
            endpoint = "/api/v1/market/sp100/symbols/\(symbol)/1d?days=90"
        case "1Y":
            endpoint = "/api/v1/market/sp100/symbols/\(symbol)/1d?days=365"
        default:
            endpoint = "/api/v1/market/sp100/symbols/\(symbol)/1d?days=30"
        }
        
        return try await makeRequest(
            endpoint: endpoint,
            responseType: ChartDataResponse.self,
            requiresAuth: true
        )
    }
    
    // Clear cache on logout or when needed
    func clearCache() {
        // Clear URL cache
        cache.removeAllCachedResponses()
        
        // Clear our custom market data cache
        Task { @MainActor in
            MarketDataCache.shared.clearCache()
        }
    }
    
    // Force clear all caches (for debugging)
    func forceClearAllCaches() {
        URLCache.shared.removeAllCachedResponses()
        cache.removeAllCachedResponses()
        
        Task { @MainActor in
            MarketDataCache.shared.clearCache()
        }
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
