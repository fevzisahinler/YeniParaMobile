import Foundation

class ForumService {
    static let shared = ForumService()
    private let baseURL = "http://192.168.1.210:4000/api/v1/forum"
    
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
    func getThreadDetail(threadId: Int, token: String) async throws -> ForumThreadDetail {
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
        let apiResponse = try decoder.decode(ForumThreadDetailResponse.self, from: data)
        
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

struct ForumThreadDetailResponse: Codable {
    let data: ForumThreadDetail
    let success: Bool
}

struct ForumThreadDetail: Codable {
    let id: Int
    let topicId: Int
    let userId: Int
    let title: String
    let content: String
    let tags: String
    let viewCount: Int
    let replyCount: Int
    let likeCount: Int
    let dislikeCount: Int
    let score: Int
    let isPinned: Bool
    let isLocked: Bool
    let isFeatured: Bool
    let isActive: Bool
    let lastReplyAt: String?
    let createdAt: String
    let updatedAt: String
    let topic: ForumTopic?
    let user: ForumUser?
    let votes: [ForumVote]?
    let replies: [ForumReply]?
    
    enum CodingKeys: String, CodingKey {
        case id, title, content, tags, score, topic, user, votes, replies
        case topicId = "topic_id"
        case userId = "user_id"
        case viewCount = "view_count"
        case replyCount = "reply_count"
        case likeCount = "like_count"
        case dislikeCount = "dislike_count"
        case isPinned = "is_pinned"
        case isLocked = "is_locked"
        case isFeatured = "is_featured"
        case isActive = "is_active"
        case lastReplyAt = "last_reply_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Reply Models
struct ForumReply: Codable {
    let id: Int
    let threadId: Int
    let userId: Int
    let parentId: Int?
    let content: String
    let likeCount: Int
    let dislikeCount: Int
    let score: Int
    let isBestAnswer: Bool
    let isEdited: Bool
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    let user: ForumUser?
    let children: [ForumReply]?
    
    enum CodingKeys: String, CodingKey {
        case id, content, score, user, children
        case threadId = "thread_id"
        case userId = "user_id"
        case parentId = "parent_id"
        case likeCount = "like_count"
        case dislikeCount = "dislike_count"
        case isBestAnswer = "is_best_answer"
        case isEdited = "is_edited"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ForumReplyResponse: Codable {
    let data: ForumReply
    let success: Bool
}

struct CreateReplyRequest: Codable {
    let content: String
    let parentId: Int?
    
    enum CodingKeys: String, CodingKey {
        case content
        case parentId = "parent_id"
    }
}

struct ForumVote: Codable {
    let id: Int
    let userId: Int
    let threadId: Int?
    let replyId: Int?
    let voteType: Int
    let createdAt: String
    let user: ForumUser?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case threadId = "thread_id"
        case replyId = "reply_id"
        case voteType = "vote_type"
        case createdAt = "created_at"
        case user
    }
}