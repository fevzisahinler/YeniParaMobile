import Foundation

// MARK: - Quiz Models
struct QuizQuestion: Codable, Identifiable {
    let id: Int
    let questionText: String
    let questionOrder: Int
    let options: [QuizOption]
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case questionText = "question_text"
        case questionOrder = "question_order"
        case options
        case createdAt = "created_at"
    }
}

struct QuizOption: Codable, Identifiable {
    let id: Int
    let questionId: Int
    let optionText: String
    let optionOrder: Int
    let points: Int
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case questionId = "question_id"
        case optionText = "option_text"
        case optionOrder = "option_order"
        case points
        case createdAt = "created_at"
    }
}

// MARK: - Request Models
struct QuizSubmitRequest: Codable {
    let answers: [String: Int]
}

// MARK: - Response Models
struct QuizQuestionsResponse: Codable {
    let data: QuizQuestionsData
    let success: Bool
}

struct QuizQuestionsData: Codable {
    let questions: [QuizQuestion]
    let total: Int
}

struct QuizSubmitResponse: Codable {
    let data: QuizSubmitData
    let success: Bool
}

struct QuizSubmitData: Codable {
    let investorProfile: InvestorProfile
    let totalPoints: Int
    let quizCompleted: Bool
    let recommendations: [String]
    
    enum CodingKeys: String, CodingKey {
        case investorProfile = "investor_profile"
        case totalPoints = "total_points"
        case quizCompleted = "quiz_completed"
        case recommendations
    }
}

struct InvestorProfile: Codable {
    let id: Int
    let profileType: String
    let name: String
    let description: String
    let minPoints: Int
    let maxPoints: Int
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
        case name
        case description
        case minPoints = "min_points"
        case maxPoints = "max_points"
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

struct QuizStatusResponse: Codable {
    let data: QuizStatusData
    let success: Bool
}

struct QuizStatusData: Codable {
    let quizCompleted: Bool
    let investorProfile: InvestorProfile?
    
    enum CodingKeys: String, CodingKey {
        case quizCompleted = "quiz_completed"
        case investorProfile = "investor_profile"
    }
}
