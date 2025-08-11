import Foundation

// MARK: - User Profile Response Models

struct UserProfileResponse: Codable {
    let data: UserProfileData
    let success: Bool
}

struct UserProfileData: Codable {
    let activity: UserActivity
    let badges: UserBadges
    let forumStats: ForumStats
    let investorProfile: InvestorProfile
    let user: UserInfo
    
    enum CodingKeys: String, CodingKey {
        case activity
        case badges
        case forumStats = "forum_stats"
        case investorProfile = "investor_profile"
        case user
    }
}

struct UserActivity: Codable {
    let followedStocks: Int
    let forumThreads: Int
    let quizCompletedAt: String
    let stockComments: Int
    
    enum CodingKeys: String, CodingKey {
        case followedStocks = "followed_stocks"
        case forumThreads = "forum_threads"
        case quizCompletedAt = "quiz_completed_at"
        case stockComments = "stock_comments"
    }
}

struct UserBadges: Codable {
    let count: Int
    let earnedBadges: [Badge]
    
    enum CodingKeys: String, CodingKey {
        case count
        case earnedBadges = "earned_badges"
    }
}

struct Badge: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let icon: String
}

struct ForumStats: Codable {
    let bestAnswers: Int
    let likesReceived: Int
    let repliesCreated: Int
    let reputationScore: Int
    let threadsCreated: Int
    let title: String
    
    enum CodingKeys: String, CodingKey {
        case bestAnswers = "best_answers"
        case likesReceived = "likes_received"
        case repliesCreated = "replies_created"
        case reputationScore = "reputation_score"
        case threadsCreated = "threads_created"
        case title
    }
}

struct UserInfo: Codable {
    let createdAt: String
    let email: String
    let fullName: String
    let id: Int
    let investorProfileId: Int
    let isEmailVerified: Bool
    let isQuizCompleted: Bool
    let phoneNumber: String
    let username: String
    
    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case email
        case fullName = "full_name"
        case id
        case investorProfileId = "investor_profile_id"
        case isEmailVerified = "is_email_verified"
        case isQuizCompleted = "is_quiz_completed"
        case phoneNumber = "phone_number"
        case username
    }
}

// MARK: - Update Profile Response

struct UpdateProfileResponse: Codable {
    let data: UpdateProfileData
    let success: Bool
}

struct UpdateProfileData: Codable {
    let message: String
    let user: UpdatedUserInfo
}

struct UpdatedUserInfo: Codable {
    let email: String
    let fullName: String
    let id: Int
    let phoneNumber: String
    let username: String
    
    enum CodingKeys: String, CodingKey {
        case email
        case fullName = "full_name"
        case id
        case phoneNumber = "phone_number"
        case username
    }
}

// MARK: - Public User Profile Response

struct PublicUserProfileResponse: Codable {
    let data: PublicUserProfileData
    let success: Bool
}

struct PublicUserProfileData: Codable {
    let badges: [Badge]
    let forumStats: ForumStats
    let investorProfile: InvestorProfile
    let memberSince: String
    let recentThreads: [RecentThread]
    let username: String
    
    enum CodingKeys: String, CodingKey {
        case badges
        case forumStats = "forum_stats"
        case investorProfile = "investor_profile"
        case memberSince = "member_since"
        case recentThreads = "recent_threads"
        case username
    }
}

struct RecentThread: Codable, Identifiable {
    let id: Int
    let title: String
    let createdAt: String
    let repliesCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case createdAt = "created_at"
        case repliesCount = "replies_count"
    }
}

// MARK: - Stock Follow Response

struct StockFollowResponse: Codable {
    let data: StockFollowData
    let success: Bool
}

struct StockFollowData: Codable {
    let follower: StockFollower
    let message: String
}

struct StockFollower: Codable {
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

// Note: FollowedStocksResponse and FollowedStock are defined in StockCommentModels.swift