import Foundation

// MARK: - API Client Protocol
protocol APIClientProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
    func requestData(_ endpoint: APIEndpoint) async throws -> Data
    func upload(_ endpoint: APIEndpoint, data: Data) async throws -> Data
}

// MARK: - API Configuration
struct APIConfiguration {
    let baseURL: String
    let timeout: TimeInterval
    let maxRetries: Int
    
    static let `default` = APIConfiguration(
        baseURL: {
            #if DEBUG
            return "http://192.168.1.210:4000"
            #else
            return "https://localhost:4000"
            #endif
        }(),
        timeout: 30,
        maxRetries: 3
    )
} 

// MARK: - API Client
@MainActor
final class APIClient: APIClientProtocol {
    // MARK: - Properties
    static let shared = APIClient()
    
    private let configuration: APIConfiguration
    private let session: URLSession
    private weak var authManager: AuthManagerProtocol?
    
    // MARK: - Initialization
    private init(configuration: APIConfiguration = .default) {
        self.configuration = configuration
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeout
        sessionConfig.timeoutIntervalForResource = configuration.timeout * 2
        sessionConfig.waitsForConnectivity = true
        sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        self.session = URLSession(configuration: sessionConfig)
    }
    
    // MARK: - Public Methods
    func setAuthManager(_ authManager: AuthManagerProtocol) {
        self.authManager = authManager
    }
    
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let data = try await performRequest(endpoint)
        return try decode(T.self, from: data)
    }
    
    func requestData(_ endpoint: APIEndpoint) async throws -> Data {
        return try await performRequest(endpoint)
    }
    
    func upload(_ endpoint: APIEndpoint, data: Data) async throws -> Data {
        var urlRequest = try createURLRequest(for: endpoint)
        urlRequest.httpBody = data
        urlRequest.setValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
        
        let (responseData, response) = try await session.data(for: urlRequest)
        try validateResponse(response, data: responseData)
        return responseData
    }
    
    // MARK: - Private Methods
    private func performRequest(_ endpoint: APIEndpoint, retryCount: Int = 0) async throws -> Data {
        // Check network
        guard NetworkMonitor.shared.isConnected else {
            throw APIError.networkError
        }
        
        do {
            let urlRequest = try createURLRequest(for: endpoint)
            let (data, response) = try await session.data(for: urlRequest)
            
            // Handle 401 - Token refresh
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 401,
               endpoint.requiresAuth,
               let authManager = authManager {
                
                let refreshed = await authManager.refreshTokenIfNeeded()
                if refreshed {
                    // Retry with new token
                    return try await performRequest(endpoint, retryCount: retryCount)
                } else {
                    // Refresh failed, logout
                    await authManager.logout()
                    throw APIError.unauthorized
                }
            }
            
            try validateResponse(response, data: data)
            return data
            
        } catch {
            // Retry logic for retryable errors
            if retryCount < configuration.maxRetries,
               let apiError = error as? APIError,
               apiError.isRetryable {
                
                // Exponential backoff
                let delay = pow(2.0, Double(retryCount))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                return try await performRequest(endpoint, retryCount: retryCount + 1)
            }
            
            throw error
        }
    }
    
    private func createURLRequest(for endpoint: APIEndpoint) throws -> URLRequest {
        var urlRequest = try endpoint.urlRequest(
            baseURL: configuration.baseURL,
            accessToken: authManager?.accessToken
        )
        
        // Add additional headers if needed
        if endpoint.requiresAuth, authManager?.accessToken == nil {
            throw APIError.unauthorized
        }
        
        return urlRequest
    }
    
    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            // Success
            return
            
        case 401:
            throw APIError.unauthorized
            
        case 400...499:
            // Client error - try to decode error message
            if let errorResponse = try? decode(ErrorResponse.self, from: data) {
                throw APIError.serverErrorWithMessage(httpResponse.statusCode, errorResponse.displayMessage)
            }
            throw APIError.serverError(httpResponse.statusCode)
            
        case 500...599:
            // Server error
            throw APIError.serverError(httpResponse.statusCode)
            
        default:
            throw APIError.invalidResponse
        }
    }
    
    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(type, from: data)
        } catch {
            print("Decoding error for \(type): \(error)")
            throw APIError.decodingError
        }
    }
}

// MARK: - Auth Manager Protocol
protocol AuthManagerProtocol: AnyObject {
    var accessToken: String? { get }
    var refreshToken: String? { get }
    
    func refreshTokenIfNeeded() async -> Bool
    func logout() async
}
