import Foundation

// MARK: - Comment Models
struct StockComment: Codable, Identifiable {
    let id: Int
    let symbolCode: String
    let userId: Int
    let parentId: Int?
    let content: String
    let sentiment: CommentSentiment
    let likeCount: Int
    let dislikeCount: Int
    let replyCount: Int
    let score: Int
    let isAnalysis: Bool
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    let user: CommentUser
    var userVote: VoteType?
    
    enum CodingKeys: String, CodingKey {
        case id
        case symbolCode = "symbol_code"
        case userId = "user_id"
        case parentId = "parent_id"
        case content
        case sentiment
        case likeCount = "like_count"
        case dislikeCount = "dislike_count"
        case replyCount = "reply_count"
        case score
        case isAnalysis = "is_analysis"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user
        case userVote = "user_vote"
    }
}

struct CommentUser: Codable {
    let id: Int
    let username: String
    let fullName: String
    let phoneNumber: String?
    let email: String
    let isComplete: Bool
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

// MARK: - Comment Requests/Responses
struct CommentsListResponse: Codable {
    let data: CommentsData
    let success: Bool
}

struct CommentsData: Codable {
    let comments: [StockComment]
    let pagination: PaginationInfo?
}

struct PaginationInfo: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
    
    enum CodingKeys: String, CodingKey {
        case page, limit, total
        case totalPages = "total_pages"
    }
}

struct CreateCommentRequest: Codable {
    let content: String
    let sentiment: CommentSentiment
    let isAnalysis: Bool
    let parentId: Int?
    
    enum CodingKeys: String, CodingKey {
        case content
        case sentiment
        case isAnalysis = "is_analysis"
        case parentId = "parent_id"
    }
}

struct CreateCommentResponse: Codable {
    let data: StockComment
    let success: Bool
}

struct VoteCommentRequest: Codable {
    let voteType: Int
    
    enum CodingKeys: String, CodingKey {
        case voteType = "vote_type"
    }
}

struct VoteCommentResponse: Codable {
    let data: VoteData
    let success: Bool
}

struct VoteData: Codable {
    let dislikeCount: Int
    let likeCount: Int
    let score: Int
    
    enum CodingKeys: String, CodingKey {
        case dislikeCount = "dislike_count"
        case likeCount = "like_count"
        case score
    }
}

// MARK: - Sentiment Models
struct StockSentimentResponse: Codable {
    let data: SentimentData
    let success: Bool
}

struct SentimentData: Codable {
    let dailySentiments: [DailySentiment]
    let overall: OverallSentiment
    
    enum CodingKeys: String, CodingKey {
        case dailySentiments = "daily_sentiments"
        case overall
    }
}

struct DailySentiment: Codable, Identifiable {
    let id: Int
    let symbolCode: String
    let date: String
    let bullishCount: Int
    let bearishCount: Int
    let neutralCount: Int
    let totalComments: Int
    let sentimentScore: Double
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case symbolCode = "symbol_code"
        case date
        case bullishCount = "bullish_count"
        case bearishCount = "bearish_count"
        case neutralCount = "neutral_count"
        case totalComments = "total_comments"
        case sentimentScore = "sentiment_score"
        case createdAt = "created_at"
    }
}

struct OverallSentiment: Codable {
    let bearishCount: Int
    let bullishCount: Int
    let neutralCount: Int
    let sentimentScore: Double
    let totalComments: Int
    
    enum CodingKeys: String, CodingKey {
        case bearishCount = "bearish_count"
        case bullishCount = "bullish_count"
        case neutralCount = "neutral_count"
        case sentimentScore = "sentiment_score"
        case totalComments = "total_comments"
    }
}

// MARK: - Follow Models
struct FollowStockRequest: Codable {
    let notifyOnNews: Bool
    let notifyOnComment: Bool
    
    enum CodingKeys: String, CodingKey {
        case notifyOnNews = "notify_on_news"
        case notifyOnComment = "notify_on_comment"
    }
}

struct FollowedStocksResponse: Codable {
    let data: FollowedStocksData
    let success: Bool
}

struct FollowedStocksData: Codable {
    let count: Int
    let stocks: [FollowedStock]
}

struct FollowedStock: Codable, Identifiable {
    let id: Int
    let userId: Int
    let symbolCode: String
    let notifyOnNews: Bool
    let notifyOnComment: Bool
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case symbolCode = "symbol_code"
        case notifyOnNews = "notify_on_news"
        case notifyOnComment = "notify_on_comment"
        case createdAt = "created_at"
    }
}

// MARK: - Enums
enum CommentSentiment: String, Codable, CaseIterable {
    case bullish = "bullish"
    case bearish = "bearish"
    case neutral = "neutral"
    
    var title: String {
        switch self {
        case .bullish:
            return "Yükseliş"
        case .bearish:
            return "Düşüş"
        case .neutral:
            return "Nötr"
        }
    }
    
    var icon: String {
        switch self {
        case .bullish:
            return "arrow.up.circle.fill"
        case .bearish:
            return "arrow.down.circle.fill"
        case .neutral:
            return "minus.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .bullish:
            return "green"
        case .bearish:
            return "red"
        case .neutral:
            return "gray"
        }
    }
}

enum VoteType: Int, Codable {
    case none = 0
    case like = 1
    case dislike = -1
}

enum CommentSortType: String {
    case latest = "latest"
    case popular = "popular"
    case oldest = "oldest"
}

// MARK: - Weekly Stats Models
struct WeeklyStatsResponse: Codable {
    let data: WeeklyStatsData
    let success: Bool
}

struct WeeklyStatsData: Codable {
    let currentWeek: CurrentWeek
    let weeklyStats: [WeeklyStat]
    
    enum CodingKeys: String, CodingKey {
        case currentWeek = "current_week"
        case weeklyStats = "weekly_stats"
    }
}

struct CurrentWeek: Codable {
    let userVote: String?
    let weekNumber: Int
    let year: Int
    
    enum CodingKeys: String, CodingKey {
        case userVote = "user_vote"
        case weekNumber = "week_number"
        case year
    }
}

struct WeeklyStat: Codable, Identifiable {
    let id: Int
    let symbolCode: String
    let weekNumber: Int
    let year: Int
    let likeCount: Int
    let dislikeCount: Int
    let likePercentage: Double
    let totalVotes: Int
    let weekStart: String
    let weekEnd: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case symbolCode = "symbol_code"
        case weekNumber = "week_number"
        case year
        case likeCount = "like_count"
        case dislikeCount = "dislike_count"
        case likePercentage = "like_percentage"
        case totalVotes = "total_votes"
        case weekStart = "week_start"
        case weekEnd = "week_end"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Weekly Vote Request
struct WeeklyVoteRequest: Codable {
    let voteType: String
    let reason: String
    
    enum CodingKeys: String, CodingKey {
        case voteType = "vote_type"
        case reason
    }
}