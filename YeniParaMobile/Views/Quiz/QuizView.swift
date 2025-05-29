import SwiftUI

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

struct QuizQuestionsResponse: Codable {
    let data: QuizQuestionsData
    let success: Bool
}

struct QuizQuestionsData: Codable {
    let questions: [QuizQuestion]
    let total: Int
}

struct QuizSubmitRequest: Codable {
    let answers: [String: Int]
}

// MARK: - Updated API Response Models (matching your actual API)
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
    
    enum CodingKeys: String, CodingKey {
        case quizCompleted = "quiz_completed"
    }
}

// MARK: - Quiz ViewModel
@MainActor
class QuizViewModel: ObservableObject {
    @Published var questions: [QuizQuestion] = []
    @Published var currentQuestionIndex = 0
    @Published var selectedAnswers: [Int: Int] = [:]
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isCompleted = false
    @Published var quizResult: QuizSubmitData?
    @Published var showResult = false
    
    private let authViewModel: AuthViewModel
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }
    
    var currentQuestion: QuizQuestion? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    var selectedOptionForCurrentQuestion: Int? {
        guard let question = currentQuestion else { return nil }
        return selectedAnswers[question.id]
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
    
    func loadQuestions() async {
        isLoading = true
        showError = false
        
        do {
            guard let url = URL(string: "http://localhost:4000/api/v1/quiz/questions") else {
                throw QuizError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if let token = authViewModel.accessToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw QuizError.invalidResponse
            }
            
            if httpResponse.statusCode == 401 {
                // Token expired, try to refresh
                if let refreshToken = authViewModel.refreshToken {
                    let refreshSuccess = await authViewModel.refreshAccessToken(refreshToken: refreshToken)
                    if refreshSuccess {
                        // Retry with new token
                        if let newToken = authViewModel.accessToken {
                            request.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                        }
                        let (newData, newResponse) = try await URLSession.shared.data(for: request)
                        guard let newHttpResponse = newResponse as? HTTPURLResponse,
                              newHttpResponse.statusCode == 200 else {
                            throw QuizError.serverError((newResponse as? HTTPURLResponse)?.statusCode ?? 0)
                        }
                        let decoder = JSONDecoder()
                        let apiResponse = try decoder.decode(QuizQuestionsResponse.self, from: newData)
                        self.questions = apiResponse.data.questions.sorted { $0.questionOrder < $1.questionOrder }
                    } else {
                        authViewModel.logout()
                        throw QuizError.unauthorized
                    }
                } else {
                    throw QuizError.unauthorized
                }
            } else if httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                let apiResponse = try decoder.decode(QuizQuestionsResponse.self, from: data)
                
                if apiResponse.success {
                    self.questions = apiResponse.data.questions.sorted { $0.questionOrder < $1.questionOrder }
                } else {
                    throw QuizError.serverError(httpResponse.statusCode)
                }
            } else {
                throw QuizError.serverError(httpResponse.statusCode)
            }
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func selectOption(_ optionId: Int) {
        guard let question = currentQuestion else { return }
        selectedAnswers[question.id] = optionId
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
    
    private func submitQuiz() {
        Task {
            await submitQuizAnswers()
        }
    }
    
    private func submitQuizAnswers() async {
        isLoading = true
        
        do {
            guard let url = URL(string: "http://localhost:4000/api/v1/quiz/submit") else {
                throw QuizError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if let token = authViewModel.accessToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            // Convert selectedAnswers to the required format
            let answersForSubmit = selectedAnswers.mapKeys { String($0) }
            let submitRequest = QuizSubmitRequest(answers: answersForSubmit)
            
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(submitRequest)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw QuizError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                let apiResponse = try decoder.decode(QuizSubmitResponse.self, from: data)
                
                if apiResponse.success {
                    self.quizResult = apiResponse.data
                    self.isCompleted = true
                    
                    // Mark quiz as completed in AuthViewModel
                    await self.authViewModel.checkQuizStatus()
                    
                    // Show result after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.showResult = true
                        }
                    }
                } else {
                    throw QuizError.serverError(httpResponse.statusCode)
                }
            } else {
                throw QuizError.serverError(httpResponse.statusCode)
            }
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    private func handleError(_ error: Error) {
        if let quizError = error as? QuizError {
            switch quizError {
            case .invalidURL:
                errorMessage = "Geçersiz URL adresi"
            case .invalidResponse:
                errorMessage = "Sunucu yanıtı geçersiz"
            case .serverError(let code):
                errorMessage = "Sunucu hatası (Kod: \(code))"
            case .unauthorized:
                errorMessage = "Yetkilendirme hatası"
            case .networkError:
                errorMessage = "Ağ bağlantısı hatası"
            }
        } else {
            errorMessage = "Beklenmeyen bir hata oluştu"
        }
        showError = true
    }
}

enum QuizError: Error {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case unauthorized
    case networkError
}

// MARK: - Extensions
extension Dictionary {
    func mapKeys<T>(_ transform: (Key) throws -> T) rethrows -> [T: Value] {
        return Dictionary<T, Value>(uniqueKeysWithValues: try map { (try transform($0.key), $0.value) })
    }
}

// MARK: - Quiz View
struct QuizView: View {
    @ObservedObject var authVM: AuthViewModel
    @StateObject private var quizVM: QuizViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(authVM: AuthViewModel) {
        self.authVM = authVM
        self._quizVM = StateObject(wrappedValue: QuizViewModel(authViewModel: authVM))
    }
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            if quizVM.isLoading && quizVM.questions.isEmpty {
                LoadingView(message: "Quiz yükleniyor...")
            } else if quizVM.showError {
                ErrorView(message: quizVM.errorMessage) {
                    Task {
                        await quizVM.loadQuestions()
                    }
                }
            } else if quizVM.showResult {
                QuizResultView(
                    result: quizVM.quizResult,
                    onComplete: {
                        authVM.isLoggedIn = true
                        dismiss()
                    }
                )
            } else {
                QuizContentView(quizVM: quizVM)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await quizVM.loadQuestions()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    QuizView(authVM: AuthViewModel())
        .preferredColorScheme(.dark)
}

// MARK: - Quiz Content View
struct QuizContentView: View {
    @ObservedObject var quizVM: QuizViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with progress
            QuizHeaderView(
                currentQuestion: quizVM.currentQuestionIndex + 1,
                totalQuestions: quizVM.questions.count,
                progress: quizVM.progressPercentage
            ) {
                quizVM.previousQuestion()
            }
            
            // Question content
            if let question = quizVM.currentQuestion {
                QuizQuestionView(
                    question: question,
                    selectedOptionId: quizVM.selectedOptionForCurrentQuestion,
                    onOptionSelected: { optionId in
                        quizVM.selectOption(optionId)
                    }
                )
            }
            
            Spacer()
            
            // Navigation buttons
            QuizNavigationView(
                canGoBack: quizVM.currentQuestionIndex > 0,
                canProceed: quizVM.canProceed,
                isLastQuestion: quizVM.isLastQuestion,
                isLoading: quizVM.isLoading,
                onBack: {
                    quizVM.previousQuestion()
                },
                onNext: {
                    quizVM.nextQuestion()
                }
            )
        }
    }
}

// MARK: - Quiz Header View
struct QuizHeaderView: View {
    let currentQuestion: Int
    let totalQuestions: Int
    let progress: Double
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Color.clear
                    .frame(width: 24, height: 24)
                
                Spacer()
                
                Text("\(currentQuestion)/\(totalQuestions)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                
                Spacer()
                
                Color.clear
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            
            // Progress Bar
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.cardBackground)
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.secondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 8)
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Quiz Question View
struct QuizQuestionView: View {
    let question: QuizQuestion
    let selectedOptionId: Int?
    let onOptionSelected: (Int) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Question Text
                VStack(spacing: 16) {
                    Text(question.questionText)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 20)
                
                // Options
                VStack(spacing: 16) {
                    ForEach(question.options.sorted { $0.optionOrder < $1.optionOrder }) { option in
                        QuizOptionButton(
                            option: option,
                            isSelected: selectedOptionId == option.id,
                            onTap: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                onOptionSelected(option.id)
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - Quiz Option Button
struct QuizOptionButton: View {
    let option: QuizOption
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? AppColors.primary : AppColors.cardBorder,
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 12, height: 12)
                            .scaleEffect(isPressed ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)
                    }
                }
                
                // Option text
                Text(option.optionText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? AppColors.primary.opacity(0.1) : AppColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? AppColors.primary : AppColors.cardBorder,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
    }
}

// MARK: - Quiz Navigation View
struct QuizNavigationView: View {
    let canGoBack: Bool
    let canProceed: Bool
    let isLastQuestion: Bool
    let isLoading: Bool
    let onBack: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Back button
            if canGoBack {
                Button(action: onBack) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Önceki")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.cardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.cardBorder, lineWidth: 1)
                    )
                }
            } else {
                Color.clear
                    .frame(maxWidth: .infinity)
            }
            
            // Next/Submit button
            Button(action: onNext) {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            .scaleEffect(0.8)
                    } else {
                        Text(isLastQuestion ? "Tamamla" : "Sonraki")
                            .font(.system(size: 16, weight: .semibold))
                        
                        if !isLastQuestion {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canProceed && !isLoading ? AppColors.primary : AppColors.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            canProceed && !isLoading ? Color.clear : AppColors.cardBorder,
                            lineWidth: 1
                        )
                )
            }
            .disabled(!canProceed || isLoading)
            .opacity(canProceed && !isLoading ? 1.0 : 0.6)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
}

// MARK: - Quiz Result View - Updated to use new API response structure
struct QuizResultView: View {
    let result: QuizSubmitData?
    let onComplete: () -> Void
    
    @State private var showContent = false
    
    var profileTypeInfo: (title: String, description: String, color: Color, icon: String) {
        guard let profile = result?.investorProfile else {
            return ("Bilinmeyen", "Profil tipi belirlenemedi", AppColors.textSecondary, "questionmark.circle")
        }
        
        // Use the actual profile data from API
        let profileType = profile.profileType.lowercased()
        let title = profile.name
        let description = profile.description
        
        // Set color and icon based on profile type
        let color: Color
        let icon: String
        
        switch profileType {
        case "conservative":
            color = Color.blue
            icon = "shield.fill"
        case "moderate":
            color = Color.orange
            icon = "scale.3d"
        case "aggressive":
            color = AppColors.primary
            icon = "chart.line.uptrend.xyaxis"
        default:
            color = AppColors.primary
            icon = "person.crop.circle"
        }
        
        return (title, description, color, icon)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 60)
                
                // Success Animation
                if showContent {
                    VStack(spacing: 24) {
                        // Profile Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [profileTypeInfo.color, profileTypeInfo.color.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .scaleEffect(showContent ? 1.0 : 0.5)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showContent)
                            
                            Image(systemName: profileTypeInfo.icon)
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(showContent ? 1.0 : 0.5)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: showContent)
                        }
                        
                        // Result Text
                        VStack(spacing: 16) {
                            Text("Senin yatırımcı tipin:")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                                .opacity(showContent ? 1 : 0)
                                .animation(.easeInOut(duration: 0.5).delay(0.6), value: showContent)
                            
                            Text(profileTypeInfo.title)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.textPrimary)
                                .multilineTextAlignment(.center)
                                .opacity(showContent ? 1 : 0)
                                .animation(.easeInOut(duration: 0.5).delay(0.8), value: showContent)
                        }
                    }
                }
                
                // Description and Score
                if showContent {
                    VStack(spacing: 20) {
                        Text(profileTypeInfo.description)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .padding(.horizontal, 32)
                            .opacity(showContent ? 1 : 0)
                            .animation(.easeInOut(duration: 0.5).delay(1.0), value: showContent)
                        
                        if let score = result?.totalPoints {
                            HStack(spacing: 12) {
                                Text("Toplam Puan:")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)
                                
                                Text("\(score)")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(profileTypeInfo.color)
                            }
                            .opacity(showContent ? 1 : 0)
                            .animation(.easeInOut(duration: 0.5).delay(1.2), value: showContent)
                        }
                        
                        // Portfolio Allocation (if available)
                        if let profile = result?.investorProfile {
                            VStack(spacing: 12) {
                                Text("Önerilen Portföy Dağılımı")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary)
                                
                                HStack(spacing: 20) {
                                    AllocationItem(
                                        title: "Hisse",
                                        percentage: profile.stockAllocationPercentage,
                                        color: AppColors.primary
                                    )
                                    AllocationItem(
                                        title: "Tahvil",
                                        percentage: profile.bondAllocationPercentage,
                                        color: Color.blue
                                    )
                                    AllocationItem(
                                        title: "Nakit",
                                        percentage: profile.cashAllocationPercentage,
                                        color: Color.gray
                                    )
                                }
                            }
                            .padding(.vertical, 20)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(AppColors.cardBackground)
                            )
                            .padding(.horizontal, 24)
                            .opacity(showContent ? 1 : 0)
                            .animation(.easeInOut(duration: 0.5).delay(1.4), value: showContent)
                        }
                    }
                }
                
                // Recommendations
                if showContent, let recommendations = result?.recommendations, !recommendations.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Öneriler")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 12) {
                            ForEach(Array(recommendations.enumerated()), id: \.element) { index, recommendation in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("•")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(profileTypeInfo.color)
                                    
                                    Text(recommendation)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(AppColors.textSecondary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(nil)
                                }
                                .padding(.horizontal, 24)
                                .opacity(showContent ? 1 : 0)
                                .animation(.easeInOut(duration: 0.5).delay(1.6 + Double(index) * 0.1), value: showContent)
                            }
                        }
                    }
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.cardBackground)
                    )
                    .padding(.horizontal, 24)
                }
                
                Spacer(minLength: 40)
                
                // Complete Button
                if showContent {
                    Button(action: onComplete) {
                        HStack(spacing: 12) {
                            Text("Uygulamaya Geç")
                                .font(.system(size: 18, weight: .semibold))
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppColors.primary)
                        .cornerRadius(16)
                        .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 24)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5).delay(2.0), value: showContent)
                }
                
                Spacer(minLength: 40)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    showContent = true
                }
            }
        }
    }
}

// MARK: - Allocation Item Component
struct AllocationItem: View {
    let title: String
    let percentage: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(percentage)%")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
