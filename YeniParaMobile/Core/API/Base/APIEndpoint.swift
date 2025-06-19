import Foundation

// MARK: - API Endpoint Protocol
protocol APIEndpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var parameters: [String: Any]? { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Data? { get }
    var requiresAuth: Bool { get }
    var timeout: TimeInterval { get }
}

extension APIEndpoint {
    var headers: [String: String]? {
        var defaultHeaders = [
            "Content-Type": "application/json",
            "X-Platform": "iOS",
            "X-App-Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        ]
        return defaultHeaders
    }
    
    var parameters: [String: Any]? { nil }
    var queryItems: [URLQueryItem]? { nil }
    var body: Data? { nil }
    var requiresAuth: Bool { true }
    var timeout: TimeInterval { 30 }
}

// MARK: - Convenience Methods
extension APIEndpoint {
    func urlRequest(baseURL: String, accessToken: String? = nil) throws -> URLRequest {
        // Build URL
        guard var components = URLComponents(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        
        // Add query items
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeout
        
        // Add headers
        headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        // Add auth header if needed
        if requiresAuth, let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add body
        request.httpBody = body
        
        return request
    }
    
    func encodeBody<T: Encodable>(_ object: T) -> Data? {
        try? JSONEncoder().encode(object)
    }
}
