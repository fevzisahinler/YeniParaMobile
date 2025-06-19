import SwiftUI
import Combine

@MainActor
final class QuizViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var questions: [QuizQuestion] = []
    @Published var currentQuestionIndex = 0
    @Published var selectedAnswers: [Int: Int] = [:]
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isCompleted = false
    @Published var quizResult: QuizSubmitData?
    @Published var showResult = false
    
    // MARK: - Private Properties
    private let quizService: QuizServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var currentQuestion: QuizQuestion? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    var selectedOptionForCurrentQuestion: Int? {
        guard let question = currentQuestion else { return nil }
        guard let storedOptionOrder = selectedAnswers[question.id] else { return nil }
        return question.options.first(where: { $0.optionOrder == storedOptionOrder })?.id
    }
    
    var canProceed: Bool {
        selectedOptionForCurrentQuestion != nil
    }
    
    var progressPercentage: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex + 1) / Double(questions.count)
    }
    
    var isLastQuestion: Bool {
        currentQuestionIndex >= questions.count - 1
    }
    
    // MARK: - Initialization
    init(quizService: QuizServiceProtocol = ServiceLocator.quizService) {
        self.quizService = quizService
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        quizService.quizStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if let status = status {
                    self?.isCompleted = status.quizCompleted
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func loadQuestions() async {
        isLoading = true
        showError = false
        
        do {
            questions = try await quizService.getQuestions()
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func selectOption(_ optionId: Int) {
        guard let question = currentQuestion else { return }
        
        if let selectedOption = question.options.first(where: { $0.id == optionId }) {
            selectedAnswers[question.id] = selectedOption.optionOrder
        }
    }
    
    func nextQuestion() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if isLastQuestion {
                submitQuiz()
            } else {
                currentQuestionIndex += 1
            }
        }
    }
    
    func previousQuestion() {
        guard currentQuestionIndex > 0 else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentQuestionIndex -= 1
        }
    }
    
    // MARK: - Private Methods
    private func submitQuiz() {
        Task {
            await submitAnswers()
        }
    }
    
    private func submitAnswers() async {
        isLoading = true
        
        do {
            // Convert to required format: question_id (String) -> option_order (Int)
            let answersForSubmit = selectedAnswers.reduce(into: [String: Int]()) { result, item in
                result[String(item.key)] = item.value
            }
            
            let result = try await quizService.submitAnswers(answersForSubmit)
            
            self.quizResult = result
            self.isCompleted = true
            self.showResult = true
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    private func handleError(_ error: Error) {
        if let quizError = error as? QuizError {
            errorMessage = quizError.errorDescription ?? "Beklenmeyen bir hata oluştu"
        } else if let apiError = error as? APIError {
            errorMessage = apiError.errorDescription ?? "Bağlantı hatası"
        } else {
            errorMessage = error.localizedDescription
        }
        showError = true
    }
}