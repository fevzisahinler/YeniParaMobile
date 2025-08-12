import Foundation

// MARK: - Forum Category
struct ForumCategory: Identifiable, Codable {
    let id: Int
    let name: String
    let description: String
    let icon: String
    let order: Int
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    let topics: [ForumTopic]
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, icon, order, topics
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Sample data for preview
    static var sampleData: [ForumCategory] {
        [
            ForumCategory(
                id: 1,
                name: "📈 Piyasa Analizleri",
                description: "Teknik ve temel analizler, piyasa yorumları",
                icon: "📈",
                order: 1,
                isActive: true,
                createdAt: "",
                updatedAt: "",
                topics: [
                    ForumTopic(
                        id: 1,
                        categoryId: 1,
                        name: "BIST 100 Analizleri",
                        description: "BIST 100 endeksi teknik ve temel analizleri",
                        icon: "📊",
                        threadCount: 15,
                        postCount: 234,
                        order: 1,
                        isActive: true,
                        createdAt: "",
                        updatedAt: ""
                    ),
                    ForumTopic(
                        id: 2,
                        categoryId: 1,
                        name: "Hisse Analizleri",
                        description: "Bireysel hisse senetleri hakkında analizler",
                        icon: "🔍",
                        threadCount: 28,
                        postCount: 456,
                        order: 2,
                        isActive: true,
                        createdAt: "",
                        updatedAt: ""
                    )
                ]
            ),
            ForumCategory(
                id: 2,
                name: "💼 Yatırım Stratejileri",
                description: "Portföy yönetimi, risk yönetimi, strateji tartışmaları",
                icon: "💼",
                order: 2,
                isActive: true,
                createdAt: "",
                updatedAt: "",
                topics: [
                    ForumTopic(
                        id: 3,
                        categoryId: 2,
                        name: "Uzun Vadeli Yatırım",
                        description: "Buy & hold, değer yatırımı stratejileri",
                        icon: "⏰",
                        threadCount: 12,
                        postCount: 189,
                        order: 1,
                        isActive: true,
                        createdAt: "",
                        updatedAt: ""
                    )
                ]
            )
        ]
    }
}

// MARK: - Forum Topic
struct ForumTopic: Identifiable, Codable {
    let id: Int
    let categoryId: Int
    let name: String
    let description: String
    let icon: String
    let threadCount: Int
    let postCount: Int
    let order: Int
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, icon, order
        case categoryId = "category_id"
        case threadCount = "thread_count"
        case postCount = "post_count"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Forum Thread
struct ForumThread: Identifiable, Codable {
    let id: Int
    let topicId: Int
    let userId: Int
    let title: String
    let content: String
    let tags: String  // Changed from [String] to String based on API response
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
    
    var authorName: String {
        user?.fullName ?? "Anonim"
    }
    
    var tagsArray: [String] {
        tags.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
    }
    
    var formattedCreatedAt: String {
        return TimeFormatter.formatTimeAgo(createdAt)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, content, tags, score, topic, user
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
    
    // Sample data
    static var sampleData: [ForumThread] {
        [
            ForumThread(
                id: 1,
                topicId: 1,
                userId: 1,
                title: "2025 BIST 100 Hedefi: 15.000 Mümkün mü?",
                content: "2025 yılında BIST 100 endeksinin 15.000 seviyesini görebileceğini düşünüyorum. Özellikle teknoloji ve enerji sektörlerinde güçlü performans bekliyorum.",
                tags: "BIST100,2025,Analiz",
                viewCount: 234,
                replyCount: 12,
                likeCount: 45,
                dislikeCount: 3,
                score: 42,
                isPinned: false,
                isLocked: false,
                isFeatured: true,
                isActive: true,
                lastReplyAt: nil,
                createdAt: "2025-08-10T19:10:41Z",
                updatedAt: "2025-08-10T19:10:41Z",
                topic: nil,
                user: ForumUser(
                    id: 1,
                    username: "investor123",
                    fullName: "Ahmet Yılmaz",
                    phoneNumber: nil,
                    email: "",
                    isComplete: true,
                    isEmailVerified: true,
                    emailVerificationCode: nil,
                    isQuizCompleted: true,
                    investorProfileId: 1,
                    createdAt: "",
                    updatedAt: ""
                )
            ),
            ForumThread(
                id: 2,
                topicId: 1,
                userId: 2,
                title: "THYAO Teknik Analiz - Alım Fırsatı",
                content: "THYAO 280 TL seviyesinden destek buldu. RSI oversold bölgede, MACD pozitif divergence veriyor. 300 TL hedeflenebilir.",
                tags: "THYAO,TeknikAnaliz,AlımSinyali",
                viewCount: 156,
                replyCount: 8,
                likeCount: 23,
                dislikeCount: 2,
                score: 21,
                isPinned: false,
                isLocked: false,
                isFeatured: false,
                isActive: true,
                lastReplyAt: nil,
                createdAt: "2025-08-10T18:10:41Z",
                updatedAt: "2025-08-10T18:10:41Z",
                topic: nil,
                user: ForumUser(
                    id: 2,
                    username: "trader_pro",
                    fullName: "Mehmet Demir",
                    phoneNumber: nil,
                    email: "",
                    isComplete: true,
                    isEmailVerified: true,
                    emailVerificationCode: nil,
                    isQuizCompleted: true,
                    investorProfileId: 2,
                    createdAt: "",
                    updatedAt: ""
                )
            )
        ]
    }
}

// MARK: - Forum User
struct ForumUser: Codable {
    let id: Int
    let username: String
    let fullName: String
    let phoneNumber: String?
    let email: String
    let isComplete: Bool?
    let isEmailVerified: Bool
    let emailVerificationCode: String?
    let isQuizCompleted: Bool
    let investorProfileId: Int?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case username = "Username"
        case fullName = "FullName"
        case phoneNumber = "PhoneNumber"
        case email = "Email"
        case isComplete = "IsComplete"
        case isEmailVerified = "IsEmailVerified"
        case emailVerificationCode = "EmailVerificationCode"
        case isQuizCompleted = "is_quiz_completed"
        case investorProfileId = "investor_profile_id"
        case createdAt = "CreatedAt"
        case updatedAt = "UpdatedAt"
    }
}

// MARK: - API Response Models
struct ForumCategoriesResponse: Codable {
    let data: [ForumCategory]
    let success: Bool
}

struct ForumThreadResponse: Codable {
    let data: ForumThread
    let success: Bool
}

struct ForumThreadsResponse: Codable {
    let data: [ForumThread]
    let success: Bool
}

// MARK: - Create Thread Request
struct CreateThreadRequest: Codable {
    let topicId: Int
    let title: String
    let content: String
    let tags: [String]  // API accepts array, stores as comma-separated string
    
    enum CodingKeys: String, CodingKey {
        case topicId = "topic_id"
        case title, content, tags
    }
}

// MARK: - Forum Followed Stocks
struct ForumFollowedStock: Identifiable, Codable {
    let id: Int
    let userId: Int
    let symbolCode: String
    let notifyOnNews: Bool
    let notifyOnComment: Bool
    let createdAt: String
    let symbol: ForumStockSymbol
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case symbolCode = "symbol_code"
        case notifyOnNews = "notify_on_news"
        case notifyOnComment = "notify_on_comment"
        case createdAt = "created_at"
        case symbol
    }
}

struct ForumStockSymbol: Identifiable, Codable {
    var id: String { code }
    let code: String
    let name: String
    let exchange: String
    let sector: String
    let industry: String
    let marketCap: Double
    let isIndex: Bool
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case code, name, exchange, sector, industry
        case marketCap = "market_cap"
        case isIndex = "is_index"
        case isActive = "is_active"
        case createdAt = "CreatedAt"
        case updatedAt = "UpdatedAt"
    }
}

struct ForumFollowedStocksData: Codable {
    let count: Int
    let stocks: [ForumFollowedStock]
}

struct ForumFollowedStocksResponse: Codable {
    let success: Bool
    let data: ForumFollowedStocksData
}

// MARK: - Follow Stock Response
struct FollowStockResponse: Codable {
    let success: Bool
    let data: FollowStockData
}

struct FollowStockData: Codable {
    let follower: ForumFollowedStock
    let message: String
}