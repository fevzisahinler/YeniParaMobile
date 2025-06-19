import Foundation
import Combine

// MARK: - Quiz Repository Protocol
protocol QuizRepositoryProtocol {
    func getQuestions() async throws -> [QuizQuestion]
    func submitAnswers(_ answers: [String: Int]) async throws -> QuizSubmitData
    func getQuizStatus() async throws -> QuizStatusData
    func getQuizResult() async throws -> QuizSubmitData?
    func saveProgress(_ answers: [Int: Int]) async
    func loadProgress() async -> [Int: Int]?
    func clearProgress() async
}

// MARK: - Quiz Repository Implementation
final class QuizRepository: BaseRepository<QuizQuestion>, QuizRepositoryProtocol, CacheableRepositoryProtocol {
    // MARK: - Properties
    static let shared = QuizRepository()
    
    let apiClient: APIClient
    let cacheManager: CacheManager
    let cacheExpiry: TimeInterval = 3600 // 1 hour for questions
    
    private let progressKey = "quiz_progress"
    private let resultKey = "quiz_result"
    private let questionsKey = "quiz_questions"
    
    private var statusSubject = CurrentValueSubject<QuizStatusData?, Never>(nil)
    
    var statusPublisher: AnyPublisher<QuizStatusData?, Never> {
        statusSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    init(apiClient: APIClient = .shared, cacheManager: CacheManager = .shared) {
        self.apiClient = apiClient
        self.cacheManager = cacheManager
        super.init()
    }
    
    // MARK: - Public Methods
    func getQuestions() async throws -> [QuizQuestion] {
        // Check cache first
        if let cached: QuizQuestionsData = await getCached(key: questionsKey) {
            let sortedQuestions = cached.questions.sorted { $0.questionOrder < $1.questionOrder }
            notifyUpdate(sortedQuestions)
            return sortedQuestions
        }
        
        // Fetch from API
        let response: QuizQuestionsResponse = try await apiClient.request(
            QuizEndpoint.getQuestions
        )
        
        guard response.success else {
            throw RepositoryError.notFound
        }
        
        // Cache for 1 hour
        await setCached(response.data, key: questionsKey)
        
        let sortedQuestions = response.data.questions.sorted { $0.questionOrder < $1.questionOrder }
        notifyUpdate(sortedQuestions)
        
        return sortedQuestions
    }
    
    func submitAnswers(_ answers: [String: Int]) async throws -> QuizSubmitData {
        guard !answers.isEmpty else {
            throw QuizError.noAnswersProvided
        }
        
        let response: QuizSubmitResponse = try await apiClient.request(
            QuizEndpoint.submitAnswers(answers)
        )
        
        guard response.success else {
            throw RepositoryError.createFailed
        }
        
        // Update status
        let status = QuizStatusData(
            quizCompleted: response.data.quizCompleted,
            investorProfile: response.data.investorProfile
        )
        statusSubject.send(status)
        
        // Cache result
        await cacheManager.set(response.data, key: resultKey, expiry: nil) // No expiry for results
        
        // Clear progress
        await clearProgress()
        
        // Track analytics
        QuizAnalytics.shared.trackQuizCompleted(
            profile: response.data.investorProfile,
            totalPoints: response.data.totalPoints,
            duration: 0 // Would need to track actual duration
        )
        
        return response.data
    }
    
    func getQuizStatus() async throws -> QuizStatusData {
        // Return cached status if available
        if let currentStatus = statusSubject.value {
            return currentStatus
        }
        
        // Fetch from API
        let response: QuizStatusResponse = try await apiClient.request(
            QuizEndpoint.getStatus
        )
        
        guard response.success else {
            throw RepositoryError.notFound
        }
        
        statusSubject.send(response.data)
        return response.data
    }
    
    func getQuizResult() async throws -> QuizSubmitData? {
        // Check cache first
        if let cached: QuizSubmitData = await cacheManager.get(key: resultKey) {
            return cached
        }
        
        // Check if quiz is completed
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
        await cacheManager.set(response.data, key: resultKey, expiry: nil)
        
        return response.data
    }
    
    // MARK: - Progress Management
    func saveProgress(_ answers: [Int: Int]) async {
        let data = try? JSONEncoder().encode(answers)
        UserDefaultsRepository.shared.set(data, for: progressKey)
    }
    
    func loadProgress() async -> [Int: Int]? {
        guard let data = UserDefaultsRepository.shared.get(Data.self, for: progressKey) else {
            return nil
        }
        
        return try? JSONDecoder().decode([Int: Int].self, from: data)
    }
    
    func clearProgress() async {
        UserDefaultsRepository.shared.remove(for: progressKey)
    }
    
    // MARK: - Cache Methods
    func getCached<T: Codable>(key: String) async -> T? {
        return await cacheManager.get(key: key)
    }
    
    func setCached<T: Codable>(_ entity: T, key: String) async {
        await cacheManager.set(entity, key: key, expiry: cacheExpiry)
    }
    
    func invalidateCache(key: String) async {
        await cacheManager.remove(key: key)
    }
}

// MARK: - Quiz Analytics
extension QuizAnalytics {
    func trackQuizCompleted(profile: InvestorProfile, totalPoints: Int, duration: TimeInterval) {
        print("📊 Quiz completed: \(profile.name) with \(totalPoints) points in \(duration)s")
        
        // Store analytics data
        var analytics = getAnalyticsData()
        analytics.completions += 1
        analytics.lastCompletedDate = Date()
        analytics.profileDistribution[profile.profileType, default: 0] += 1
        analytics.averageScore = ((analytics.averageScore * Double(analytics.completions - 1)) + Double(totalPoints)) / Double(analytics.completions)
        
        saveAnalyticsData(analytics)
    }
    
    private func getAnalyticsData() -> QuizAnalyticsData {
        guard let data = UserDefaults.standard.data(forKey: "quiz_analytics"),
              let analytics = try? JSONDecoder().decode(QuizAnalyticsData.self, from: data) else {
            return QuizAnalyticsData()
        }
        return analytics
    }
    
    private func saveAnalyticsData(_ analytics: QuizAnalyticsData) {
        if let data = try? JSONEncoder().encode(analytics) {
            UserDefaults.standard.set(data, forKey: "quiz_analytics")
        }
    }
}

// MARK: - Analytics Data Model
private struct QuizAnalyticsData: Codable {
    var completions: Int = 0
    var abandonments: Int = 0
    var averageScore: Double = 0
    var averageDuration: TimeInterval = 0
    var lastCompletedDate: Date?
    var profileDistribution: [String: Int] = [:]
}

// MARK: - Quiz Session Manager
final class QuizSessionManager {
    static let shared = QuizSessionManager()
    
    private let repository: QuizRepositoryProtocol
    private var sessionStartTime: Date?
    private var sessionAnswers: [Int: Int] = [:]
    
    init(repository: QuizRepositoryProtocol = QuizRepository.shared) {
        self.repository = repository
    }
    
    func startSession() {
        sessionStartTime = Date()
        sessionAnswers.removeAll()
        
        // Load saved progress
        Task {
            if let progress = await repository.loadProgress() {
                sessionAnswers = progress
            }
        }
    }
    
    func endSession() {
        let duration = sessionStartTime?.timeIntervalSinceNow ?? 0
        
        // Track abandonment if not completed
        if !sessionAnswers.isEmpty {
            QuizAnalytics.shared.trackQuizAbandoned(
                atQuestion: sessionAnswers.count,
                timeSpent: abs(duration)
            )
        }
        
        sessionStartTime = nil
        sessionAnswers.removeAll()
    }
    
    func saveAnswer(questionId: Int, optionOrder: Int) {
        sessionAnswers[questionId] = optionOrder
        
        // Auto-save progress
        Task {
            await repository.saveProgress(sessionAnswers)
        }
    }
    
    func getSessionDuration() -> TimeInterval {
        guard let startTime = sessionStartTime else { return 0 }
        return abs(startTime.timeIntervalSinceNow)
    }
    
    func getAnsweredCount() -> Int {
        return sessionAnswers.count
    }
    
    func resetSession() {
        sessionStartTime = nil
        sessionAnswers.removeAll()
        
        Task {
            await repository.clearProgress()
        }
    }
}
