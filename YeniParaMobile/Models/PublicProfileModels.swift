import Foundation

// MARK: - Public Profile Response
struct PublicProfileResponse: Codable {
    let success: Bool
    let data: PublicProfileData
}

struct PublicProfileData: Codable {
    let username: String
    let memberSince: String
    let badges: [UserBadge]
    let forumStats: PublicForumStats
    let investorProfile: PublicInvestorProfile
    let recentThreads: [PublicRecentThread]
    
    enum CodingKeys: String, CodingKey {
        case username
        case memberSince = "member_since"
        case badges
        case forumStats = "forum_stats"
        case investorProfile = "investor_profile" 
        case recentThreads = "recent_threads"
    }
}

// MARK: - User Badge
struct UserBadge: Codable, Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let description: String
    let earnedAt: String
    
    enum CodingKeys: String, CodingKey {
        case name, icon, description
        case earnedAt = "earned_at"
    }
}

// MARK: - Public Forum Stats
struct PublicForumStats: Codable {
    let threadsCreated: Int
    let bestAnswers: Int
    let likesReceived: Int
    let reputationScore: Int
    let title: String
    
    enum CodingKeys: String, CodingKey {
        case threadsCreated = "threads_created"
        case bestAnswers = "best_answers"
        case likesReceived = "likes_received"
        case reputationScore = "reputation_score"
        case title
    }
}

// MARK: - Public Investor Profile
struct PublicInvestorProfile: Codable {
    let id: Int
    let profileType: String
    let name: String
    let nickname: String
    let icon: String
    let description: String
    let goals: String
    let advantages: String
    let disadvantages: String
    let riskTolerance: String
    let investmentHorizon: String
    let preferredSectors: [String]
    let stockAllocationPercentage: Int
    let bondAllocationPercentage: Int
    let cashAllocationPercentage: Int
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case profileType = "profile_type"
        case name, nickname, icon, description, goals, advantages, disadvantages
        case riskTolerance = "risk_tolerance"
        case investmentHorizon = "investment_horizon"
        case preferredSectors = "preferred_sectors"
        case stockAllocationPercentage = "stock_allocation_percentage"
        case bondAllocationPercentage = "bond_allocation_percentage"
        case cashAllocationPercentage = "cash_allocation_percentage"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Public Recent Thread
struct PublicRecentThread: Codable, Identifiable {
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
    let lastReplyAt: String
    let createdAt: String
    let updatedAt: String
    let topic: ThreadTopic
    let user: ThreadUser
    
    enum CodingKeys: String, CodingKey {
        case id
        case topicId = "topic_id"
        case userId = "user_id"
        case title, content, tags
        case viewCount = "view_count"
        case replyCount = "reply_count"
        case likeCount = "like_count"
        case dislikeCount = "dislike_count"
        case score
        case isPinned = "is_pinned"
        case isLocked = "is_locked"
        case isFeatured = "is_featured"
        case isActive = "is_active"
        case lastReplyAt = "last_reply_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case topic, user
    }
}

// MARK: - Thread Topic
struct ThreadTopic: Codable {
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
    let category: ThreadCategory
    
    enum CodingKeys: String, CodingKey {
        case id
        case categoryId = "category_id"
        case name, description, icon
        case threadCount = "thread_count"
        case postCount = "post_count"
        case order
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case category
    }
}

// MARK: - Thread Category
struct ThreadCategory: Codable {
    let id: Int
    let name: String
    let description: String
    let icon: String
    let order: Int
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, icon, order
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Thread User
struct ThreadUser: Codable {
    let id: Int
    let username: String
    let fullName: String
    let phoneNumber: String
    let email: String
    let isComplete: Bool
    let isEmailVerified: Bool
    let emailVerificationCode: String
    let isQuizCompleted: Bool
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
        case createdAt = "CreatedAt"
        case updatedAt = "UpdatedAt"
    }
}