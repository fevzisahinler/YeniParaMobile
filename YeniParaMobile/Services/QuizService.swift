import Foundation
import Combine

// MARK: - Quiz Error
enum QuizError: LocalizedError {
    case fetchQuestionsFailed
    case noAnswersProvided
    case submitFailed
    case fetchStatusFailed
    case fetchResultFailed
    case quizNotCompleted
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case unauthorized
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .fetchQuestionsFailed:
            return "Sorular yüklenemedi"
        case .noAnswersProvided:
            return "Lütfen tüm soruları cevaplayın"
        case .submitFailed:
            return "Cevaplar gönderilemedi"
        case .fetchStatusFailed:
            return "Quiz durumu alınamadı"
        case .fetchResultFailed:
            return "Quiz sonucu alınamadı"
        case .quizNotCompleted:
            return "Quiz henüz tamamlanmamış"
        case .invalidURL:
            return "Geçersiz URL adresi"
        case .invalidResponse:
            return "Sunucu yanıtı geçersiz"
        case .serverError(let code):
            return "Sunucu hatası (Kod: \(code))"
        case .unauthorized:
            return "Yetkilendirme hatası"
        case .networkError:
            return "Ağ bağlantısı hatası"
        }
    }
}

// MARK: - Quiz Service Protocol
protocol QuizServiceProtocol {
    func getQuestions() async throws -> [QuizQuestion]
    func submitAnswers(_ answers: [String: Int]) async throws -> QuizSubmitData
    func getQuizStatus() async throws -> QuizStatusData
    func getQuizResult() async throws -> QuizSubmitData?
    func calculateMatchScore(for symbol: String, profile: InvestorProfile?) -> Int
    
    // Publishers
    var quizStatusPublisher: AnyPublisher<QuizStatusData?, Never> { get }
}

// MARK: - Quiz Service Implementation
final class QuizService: QuizServiceProtocol {
    // MARK: - Properties
    static let shared = QuizService()
    
    private let apiClient: APIClient
    private let cacheManager: CacheManager
    
    private let quizStatusSubject = CurrentValueSubject<QuizStatusData?, Never>(nil)
    var quizStatusPublisher: AnyPublisher<QuizStatusData?, Never> {
        quizStatusSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    init(apiClient: APIClient = .shared, cacheManager: CacheManager = .shared) {
        self.apiClient = apiClient
        self.cacheManager = cacheManager
    }
    
    // MARK: - Public Methods
    func getQuestions() async throws -> [QuizQuestion] {
        // Check cache first
        let cacheKey = "quiz_questions"
        if let cached: QuizQuestionsResponse = await cacheManager.get(key: cacheKey) {
            return cached.data.questions
        }
        
        // Fetch from API
        let response: QuizQuestionsResponse = try await apiClient.request(
            QuizEndpoint.getQuestions
        )
        
        guard response.success else {
            throw QuizError.fetchQuestionsFailed
        }
        
        // Cache for 1 hour
        await cacheManager.set(response, key: cacheKey, expiry: 3600)
        
        // Sort by order
        let sortedQuestions = response.data.questions.sorted { $0.questionOrder < $1.questionOrder }
        
        return sortedQuestions
    }
    
    func submitAnswers(_ answers: [String: Int]) async throws -> QuizSubmitData {
        // Validate answers
        guard !answers.isEmpty else {
            throw QuizError.noAnswersProvided
        }
        
        // Submit to API
        let response: QuizSubmitResponse = try await apiClient.request(
            QuizEndpoint.submitAnswers(answers)
        )
        
        guard response.success else {
            throw QuizError.submitFailed
        }
        
        // Update status
        let statusData = QuizStatusData(
            quizCompleted: response.data.quizCompleted,
            investorProfile: response.data.investorProfile
        )
        quizStatusSubject.send(statusData)
        
        // Cache result
        await cacheManager.set(response.data, key: "quiz_result", expiry: nil)
        
        // Track analytics
        QuizAnalytics.shared.trackQuizCompleted(
            profileType: response.data.investorProfile.profileType,
            profileName: response.data.investorProfile.name,
            totalPoints: response.data.totalPoints,
            duration: 0 // Would need to track actual duration
        )
        
        return response.data
    }
    
    func getQuizStatus() async throws -> QuizStatusData {
        // Try cache first
        if let currentStatus = quizStatusSubject.value {
            return currentStatus
        }
        
        // Fetch from API
        let response: QuizStatusResponse = try await apiClient.request(
            QuizEndpoint.getStatus
        )
        
        guard response.success else {
            throw QuizError.fetchStatusFailed
        }
        
        // Update publisher
        quizStatusSubject.send(response.data)
        
        return response.data
    }
    
    func getQuizResult() async throws -> QuizSubmitData? {
        // Check cache
        if let cached: QuizSubmitData = await cacheManager.get(key: "quiz_result") {
            return cached
        }
        
        // If not in cache, check if quiz is completed
        let status = try await getQuizStatus()
        
        guard status.quizCompleted else {
            return nil
        }
        
        // Try to fetch result from API
        let response: QuizSubmitResponse = try await apiClient.request(
            QuizEndpoint.getResult
        )
        
        guard response.success else {
            return nil
        }
        
        // Cache result
        await cacheManager.set(response.data, key: "quiz_result", expiry: nil)
        
        return response.data
    }
    
    // MARK: - Helper Methods
    func calculateMatchScore(for symbol: String, profile: InvestorProfile?) -> Int {
        guard let profile = profile else { return 50 }
        
        let stockCode = symbol.lowercased()
        let profileType = profile.profileType.lowercased()
        
        // Profile-based scoring logic
        let profileScores = getProfileScores()
        
        if let scores = profileScores[profileType],
           let score = scores[stockCode] {
            return score
        }
        
        // Default scoring based on sectors
        if profile.preferredSectors.contains(where: { sector in
            stockCode.contains(sector.lowercased())
        }) {
            return 75
        }
        
        return 50
    }
    
    private func getProfileScores() -> [String: [String: Int]] {
        return [
            "conservative": [
                "jnj": 95, "ko": 92, "pfe": 88, "pg": 90, "jpm": 85,
                "wmt": 87, "vz": 86, "t": 84, "mmm": 83, "xom": 80,
                "aapl": 65, "msft": 68, "googl": 60, "amzn": 55, "tsla": 30,
                "nvda": 35, "meta": 40, "nflx": 38, "coin": 20, "riot": 15
            ],
            "moderate": [
                "aapl": 85, "msft": 88, "googl": 82, "amzn": 80, "jpm": 78,
                "v": 83, "ma": 82, "hd": 75, "dis": 77, "nke": 74,
                "jnj": 70, "ko": 68, "pfe": 65, "wmt": 72, "pg": 71,
                "tsla": 60, "nvda": 65, "meta": 63, "nflx": 58, "coin": 40
            ],
            "growth": [
                "aapl": 90, "msft": 92, "googl": 88, "amzn": 91, "tsla": 85,
                "nvda": 93, "meta": 87, "nflx": 82, "crm": 86, "adbe": 84,
                "v": 78, "ma": 77, "pypl": 80, "sq": 83, "shop": 81,
                "jnj": 50, "ko": 45, "pfe": 48, "xom": 40, "t": 35
            ],
            "aggressive": [
                "tsla": 95, "nvda": 98, "coin": 90, "riot": 88, "mara": 87,
                "pltr": 92, "nio": 85, "lcid": 83, "rivn": 82, "sofi": 86,
                "meta": 80, "nflx": 78, "arkk": 94, "spce": 89, "gme": 91,
                "jnj": 20, "ko": 15, "pfe": 25, "xom": 30, "t": 18
            ]
        ]
    }
}

// MARK: - Quiz Analytics
final class QuizAnalytics {
    static let shared = QuizAnalytics()
    
    func trackQuestionAnswered(questionId: Int, optionId: Int, timeSpent: TimeInterval) {
        // Track analytics
        print("Question \(questionId) answered with option \(optionId) in \(timeSpent)s")
    }
    
    func trackQuizCompleted(profileType: String, profileName: String, totalPoints: Int, duration: TimeInterval) {
        // Track completion
        print("Quiz completed: \(profileName) (\(profileType)) with \(totalPoints) points in \(duration)s")
    }
    
    func trackQuizAbandoned(atQuestion: Int, timeSpent: TimeInterval) {
        // Track abandonment
        print("Quiz abandoned at question \(atQuestion) after \(timeSpent)s")
    }
}
