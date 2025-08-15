import Foundation

class ForumService {
    static let shared = ForumService()
    private var baseURL: String {
        return "\(AppConfig.baseURL)/api/v1/forum"
    }
    
    private init() {}
    
    // MARK: - Get Categories
    func getCategories(token: String) async throws -> [ForumCategory] {
        guard let url = URL(string: "\(baseURL)/categories") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(ForumCategoriesResponse.self, from: data)
        
        if apiResponse.success {
            return apiResponse.data
        } else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Get Threads by Topic
    func getThreadsByTopic(topicId: Int, token: String, page: Int = 1) async throws -> ForumThreadsListResponse {
        guard let url = URL(string: "\(baseURL)/topics/\(topicId)/threads?page=\(page)&limit=20") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(ForumThreadsListResponse.self, from: data)
        
        if apiResponse.success {
            return apiResponse
        } else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Get Thread Detail
    func getThreadDetail(threadId: Int, token: String) async throws -> ThreadDetail {
        guard let url = URL(string: "\(baseURL)/threads/\(threadId)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(ThreadDetailResponse.self, from: data)
        
        if apiResponse.success {
            return apiResponse.data
        } else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Create Thread
    func createThread(topicId: Int, title: String, content: String, tags: [String], token: String) async throws -> ForumThread {
        guard let url = URL(string: "\(baseURL)/threads") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = CreateThreadRequest(
            topicId: topicId,
            title: title,
            content: content,
            tags: tags
        )
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(ForumThreadResponse.self, from: data)
        
        if apiResponse.success {
            return apiResponse.data
        } else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Create Reply
    func createReply(threadId: Int, content: String, parentId: Int? = nil, token: String) async throws -> ForumReply {
        guard let url = URL(string: "\(baseURL)/threads/\(threadId)/reply") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = CreateReplyRequest(
            content: content,
            parentId: parentId
        )
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(ForumReplyResponse.self, from: data)
        
        if apiResponse.success {
            return apiResponse.data
        } else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Like/Dislike Thread
    func voteThread(threadId: Int, voteType: ForumVoteType, token: String) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/threads/\(threadId)/vote") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["vote_type": voteType.rawValue]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        return httpResponse.statusCode == 200
    }
}

// MARK: - Vote Type
enum ForumVoteType: Int {
    case like = 1
    case dislike = -1
    case neutral = 0
}

// MARK: - Additional Response Models
struct ForumThreadsListResponse: Codable {
    let data: ForumThreadsList
    let success: Bool
}

struct ForumThreadsList: Codable {
    let threads: [ForumThread]
    let total: Int
    let page: Int
    let limit: Int
}


// MARK: - Reply Response
struct ForumReplyResponse: Codable {
    let data: ForumReply
    let success: Bool
}