import SwiftUI

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
    @Published var isDataReady = false
    
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
        
        // Get the stored option_order
        guard let storedOptionOrder = selectedAnswers[question.id] else { return nil }
        
        // Find the option with that order and return its ID for UI comparison
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
    
    func loadQuestions() async {
        isLoading = true
        showError = false
        
        do {
            guard let url = URL(string: "http://192.168.1.210:4000/api/v1/quiz/questions") else {
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
        
        // Find the option to get its order
        if let selectedOption = question.options.first(where: { $0.id == optionId }) {
            // Store option_order instead of option_id to match backend expectation
            selectedAnswers[question.id] = selectedOption.optionOrder
        }
    }
    
    func nextQuestion() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if isLastQuestion {
                submitQuiz()
            } else {
                // Clear selection animation before moving to next question
                let currentSelection = selectedOptionForCurrentQuestion
                if let question = currentQuestion, let selection = selectedAnswers[question.id] {
                    selectedAnswers[question.id] = selection
                }
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
        await MainActor.run {
            isLoading = true
        }
        
        do {
            guard let url = URL(string: "http://192.168.1.210:4000/api/v1/quiz/submit") else {
                throw QuizError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if let token = authViewModel.accessToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            // Convert selectedAnswers to the required format: question_id -> option_order
            // Backend expects option_order values, not option_id
            let answersForSubmit = selectedAnswers.mapKeys { String($0) }
            let submitRequest = QuizSubmitRequest(answers: answersForSubmit)
            
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(submitRequest)
            
            print("🚀 Submitting quiz answers: \(answersForSubmit)")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw QuizError.invalidResponse
            }
            
            print("📊 Response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                let apiResponse = try decoder.decode(QuizSubmitResponse.self, from: data)
                
                print("✅ Quiz response: \(apiResponse)")
                
                if apiResponse.success {
                    await MainActor.run {
                        self.quizResult = apiResponse.data
                        self.isCompleted = true
                        self.isLoading = false
                        self.isDataReady = true
                        
                        print("🎯 Quiz completed! Profile: \(apiResponse.data.investorProfile.name)")
                        
                        // Show result immediately without delay
                        self.showResult = true
                    }
                    
                    // Mark quiz as completed in AuthViewModel
                    await self.authViewModel.checkQuizStatus()
                } else {
                    throw QuizError.serverError(httpResponse.statusCode)
                }
            } else if httpResponse.statusCode == 401 {
                // Handle token refresh for submit endpoint too
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
                        let apiResponse = try decoder.decode(QuizSubmitResponse.self, from: newData)
                        
                        if apiResponse.success {
                            await MainActor.run {
                                self.quizResult = apiResponse.data
                                self.isCompleted = true
                                self.isLoading = false
                                
                                // Show result immediately without delay
                                self.showResult = true
                            }
                            
                            // Mark quiz as completed in AuthViewModel
                            await self.authViewModel.checkQuizStatus()
                        } else {
                            throw QuizError.serverError(newHttpResponse.statusCode)
                        }
                    } else {
                        authViewModel.logout()
                        throw QuizError.unauthorized
                    }
                } else {
                    throw QuizError.unauthorized
                }
            } else {
                throw QuizError.serverError(httpResponse.statusCode)
            }
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                handleError(error)
            }
        }
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
    func mapKeys<T: Hashable>(_ transform: (Key) throws -> T) rethrows -> [T: Value] {
        return [T: Value](uniqueKeysWithValues: try map { (try transform($0.key), $0.value) })
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
            // Background
            LinearGradient(
                colors: [
                    Color(red: 28/255, green: 29/255, blue: 36/255),
                    Color(red: 20/255, green: 21/255, blue: 28/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if quizVM.showError {
                // Error State
                ErrorView(message: quizVM.errorMessage, onRetry: {
                    Task {
                        await quizVM.loadQuestions()
                    }
                })
                .transition(.opacity)
            } else if quizVM.showResult && quizVM.quizResult != nil {
                // Result View
                QuizResultView(
                    result: quizVM.quizResult,
                    onComplete: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            authVM.isLoggedIn = true
                            authVM.isQuizCompleted = true
                        }
                        dismiss()
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            } else if !quizVM.questions.isEmpty {
                // Quiz Content - sadece sorular yüklendiyse göster
                QuizContentView(quizVM: quizVM)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: quizVM.showResult)
        .animation(.easeInOut(duration: 0.3), value: quizVM.isLoading)
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

// MARK: - Quiz Content View - FIXED LAYOUT
struct QuizContentView: View {
    @ObservedObject var quizVM: QuizViewModel
    @State private var selectedOption: Int? = nil
    @State private var showAnimation = false
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: [
                    Color(red: 28/255, green: 29/255, blue: 36/255),
                    Color(red: 20/255, green: 21/255, blue: 28/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Header
                VStack(spacing: 20) {
                    // Progress Bar
                    VStack(spacing: 12) {
                        HStack {
                            Text("Soru \(quizVM.currentQuestionIndex + 1)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Spacer()
                            
                            Text("\(quizVM.currentQuestionIndex + 1)/\(quizVM.questions.count)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        // Progress Bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 6)
                                
                                // Progress
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [AppColors.primary, AppColors.secondary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * quizVM.progressPercentage, height: 6)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: quizVM.progressPercentage)
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                }
                
                if let question = quizVM.currentQuestion {
                    ScrollView {
                        VStack(spacing: 32) {
                            // Question Text
                            Text(question.questionText)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 24)
                                .padding(.top, 40)
                            
                            // Options
                            VStack(spacing: 12) {
                                ForEach(question.options.sorted { $0.optionOrder < $1.optionOrder }) { option in
                                    QuizOptionCard(
                                        option: option,
                                        isSelected: quizVM.selectedOptionForCurrentQuestion == option.id,
                                        onTap: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                                impactFeedback.impactOccurred()
                                                quizVM.selectOption(option.id)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            // Bottom spacing for navigation
                            Spacer(minLength: 140)
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(question.id)
                }
                
                // Navigation Buttons - Fixed at bottom
                VStack(spacing: 0) {
                    // Gradient overlay for smooth transition
                    LinearGradient(
                        colors: [
                            Color(red: 28/255, green: 29/255, blue: 36/255).opacity(0),
                            Color(red: 28/255, green: 29/255, blue: 36/255)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 40)
                    
                    HStack(spacing: 12) {
                        // Back button
                        if quizVM.currentQuestionIndex > 0 {
                            Button(action: { quizVM.previousQuestion() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Önceki")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        
                        // Next/Complete button
                        Button(action: { quizVM.nextQuestion() }) {
                            HStack(spacing: 8) {
                                if quizVM.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        .scaleEffect(0.8)
                                } else {
                                    Text(quizVM.isLastQuestion ? "Tamamla" : "Sonraki")
                                        .font(.system(size: 16, weight: .semibold))
                                    
                                    if !quizVM.isLastQuestion {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                            }
                            .foregroundColor(quizVM.canProceed && !quizVM.isLoading ? .black : .white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        quizVM.canProceed && !quizVM.isLoading ?
                                        AppColors.primary :
                                        Color.white.opacity(0.15)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        quizVM.canProceed && !quizVM.isLoading ?
                                        Color.clear :
                                        Color.white.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                            .animation(.easeInOut(duration: 0.2), value: quizVM.canProceed)
                        }
                        .disabled(!quizVM.canProceed || quizVM.isLoading)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                }
                .background(
                    Color(red: 28/255, green: 29/255, blue: 36/255)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: quizVM.currentQuestionIndex)
    }
}

// MARK: - Quiz Result View - Enhanced UX/UI
struct QuizResultView: View {
    let result: QuizSubmitData?
    let onComplete: () -> Void
    
    @State private var showContent = false
    @State private var showDetails = false
    @State private var animateProgress = false
    @State private var animateAllocation = false
    
    var profileTypeInfo: (title: String, description: String, color: Color, icon: String, emoji: String) {
        guard let profile = result?.investorProfile else {
            return ("Bilinmeyen", "Profil tipi belirlenemedi", AppColors.textSecondary, "questionmark.circle", "❓")
        }
        
        let profileType = profile.profileType.lowercased()
        let title = profile.name
        let description = profile.description
        
        let color: Color
        let icon: String
        let emoji: String
        
        switch profileType {
        case "conservative":
            color = Color(red: 52/255, green: 152/255, blue: 219/255) // Soft blue
            icon = "shield.fill"
            emoji = "🛡️"
        case "moderate":
            color = Color(red: 243/255, green: 156/255, blue: 18/255) // Orange
            icon = "scale.3d"
            emoji = "⚖️"
        case "growth":
            color = AppColors.secondary
            icon = "chart.line.uptrend.xyaxis"
            emoji = "📈"
        case "aggressive":
            color = AppColors.primary
            icon = "flame.fill"
            emoji = "🔥"
        default:
            color = AppColors.primary
            icon = "person.crop.circle"
            emoji = "👤"
        }
        
        return (title, description, color, icon, emoji)
    }
    
    var body: some View {
        ZStack {
            // Gradient Background - Matching our theme
            LinearGradient(
                colors: [
                    Color(red: 28/255, green: 29/255, blue: 36/255),
                    Color(red: 20/255, green: 21/255, blue: 28/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Subtle animated background circles
            GeometryReader { geometry in
                Circle()
                    .fill(profileTypeInfo.color.opacity(0.05))
                    .frame(width: 300, height: 300)
                    .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.2)
                    .blur(radius: 80)
                    .scaleEffect(showContent ? 1.1 : 0.9)
                    .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: showContent)
                
                Circle()
                    .fill(profileTypeInfo.color.opacity(0.03))
                    .frame(width: 400, height: 400)
                    .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.7)
                    .blur(radius: 100)
                    .scaleEffect(showContent ? 1.0 : 1.2)
                    .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: showContent)
            }
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 32) {
                        // Success Animation
                        VStack(spacing: 24) {
                            // Animated Icon
                            ZStack {
                                // Outer ring animation
                                Circle()
                                    .stroke(profileTypeInfo.color.opacity(0.3), lineWidth: 3)
                                    .frame(width: 120, height: 120)
                                    .scaleEffect(showContent ? 1.1 : 0.9)
                                    .opacity(showContent ? 0 : 1)
                                    .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: showContent)
                                
                                // Main circle
                                Circle()
                                    .fill(profileTypeInfo.color.opacity(0.15))
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Circle()
                                            .stroke(profileTypeInfo.color, lineWidth: 2)
                                    )
                                    .scaleEffect(showContent ? 1.0 : 0.3)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showContent)
                                
                                // Icon
                                Image(systemName: profileTypeInfo.icon)
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(profileTypeInfo.color)
                                    .scaleEffect(showContent ? 1.0 : 0)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.3), value: showContent)
                            }
                            
                            // Title and Subtitle
                            VStack(spacing: 12) {
                                Text("Tebrikler! \(profileTypeInfo.emoji)")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .opacity(showContent ? 1 : 0)
                                    .animation(.easeOut(duration: 0.6).delay(0.5), value: showContent)
                                
                                Text("Yatırımcı tipiniz belirlendi")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.8))
                                    .opacity(showContent ? 1 : 0)
                                    .animation(.easeOut(duration: 0.6).delay(0.6), value: showContent)
                            }
                        }
                        .padding(.top, 40)
                        
                        // Profile Type Card
                        VStack(spacing: 20) {
                            // Profile Name
                            Text(profileTypeInfo.title)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(profileTypeInfo.color)
                                .opacity(showDetails ? 1 : 0)
                                .scaleEffect(showDetails ? 1 : 0.8)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.8), value: showDetails)
                            
                            // Description
                            Text(profileTypeInfo.description)
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 24)
                                .opacity(showDetails ? 1 : 0)
                                .animation(.easeOut(duration: 0.6).delay(1.0), value: showDetails)
                            
                            // Score Badge
                            if let score = result?.totalPoints {
                                HStack(spacing: 12) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(profileTypeInfo.color)
                                    
                                    Text("Puanınız: \(score)")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(profileTypeInfo.color)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(profileTypeInfo.color.opacity(0.15))
                                        .overlay(
                                            Capsule()
                                                .stroke(profileTypeInfo.color.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                .opacity(showDetails ? 1 : 0)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.2), value: showDetails)
                            }
                        }
                        .padding(.vertical, 24)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(profileTypeInfo.color.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                        
                        // Portfolio Allocation
                        if let profile = result?.investorProfile {
                            VStack(spacing: 20) {
                                HStack {
                                    Image(systemName: "chart.pie.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(profileTypeInfo.color)
                                    
                                    Text("Önerilen Portföy Dağılımı")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                
                                VStack(spacing: 16) {
                                    AllocationRow(
                                        title: "Hisse Senedi",
                                        percentage: profile.stockAllocationPercentage,
                                        color: AppColors.primary,
                                        icon: "chart.line.uptrend.xyaxis",
                                        animate: animateAllocation
                                    )
                                    
                                    AllocationRow(
                                        title: "Tahvil",
                                        percentage: profile.bondAllocationPercentage,
                                        color: Color(red: 52/255, green: 152/255, blue: 219/255),
                                        icon: "doc.text",
                                        animate: animateAllocation
                                    )
                                    
                                    AllocationRow(
                                        title: "Nakit",
                                        percentage: profile.cashAllocationPercentage,
                                        color: Color(red: 155/255, green: 89/255, blue: 182/255),
                                        icon: "banknote",
                                        animate: animateAllocation
                                    )
                                }
                                .padding(.vertical, 8)
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 20)
                            .opacity(animateAllocation ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(1.5), value: animateAllocation)
                        }
                        
                        // Recommendations
                        if let recommendations = result?.recommendations, !recommendations.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(profileTypeInfo.color)
                                    
                                    Text("Size Özel Öneriler")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                
                                VStack(spacing: 12) {
                                    ForEach(Array(recommendations.enumerated()), id: \.element) { index, recommendation in
                                        HStack(alignment: .top, spacing: 12) {
                                            Circle()
                                                .fill(profileTypeInfo.color)
                                                .frame(width: 8, height: 8)
                                                .padding(.top, 6)
                                            
                                            Text(recommendation)
                                                .font(.system(size: 14))
                                                .foregroundColor(.white.opacity(0.9))
                                                .lineSpacing(3)
                                            
                                            Spacer()
                                        }
                                        .opacity(animateProgress ? 1 : 0)
                                        .animation(.easeOut(duration: 0.5).delay(1.8 + Double(index) * 0.1), value: animateProgress)
                                    }
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        // Bottom spacing
                        Spacer(minLength: 100)
                    }
                }
                
                // Fixed Bottom Button
                VStack(spacing: 0) {
                    // Gradient fade
                    LinearGradient(
                        colors: [
                            Color(red: 28/255, green: 29/255, blue: 36/255).opacity(0),
                            Color(red: 28/255, green: 29/255, blue: 36/255)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 20)
                    
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        onComplete()
                    }) {
                        HStack(spacing: 12) {
                            Text("Uygulamaya Başla")
                                .font(.system(size: 18, weight: .bold))
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(profileTypeInfo.color)
                                .shadow(color: profileTypeInfo.color.opacity(0.3), radius: 16, x: 0, y: 8)
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                    .background(Color(red: 28/255, green: 29/255, blue: 36/255))
                    .opacity(animateProgress ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(2.0), value: animateProgress)
                }
            }
        }
        .onAppear {
            showContent = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showDetails = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                animateAllocation = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                animateProgress = true
            }
        }
    }
}

// MARK: - Allocation Row Component
struct AllocationRow: View {
    let title: String
    let percentage: Int
    let color: Color
    let icon: String
    let animate: Bool
    
    @State private var progressWidth: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("%\(percentage)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: progressWidth, height: 8)
                }
                .onAppear {
                    if animate {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                            progressWidth = geometry.size.width * CGFloat(percentage) / 100
                        }
                    }
                }
                .onChange(of: animate) { newValue in
                    if newValue {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                            progressWidth = geometry.size.width * CGFloat(percentage) / 100
                        }
                    }
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Quiz Option Card
struct QuizOptionCard: View {
    let option: QuizOption
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Selection indicator with animation
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? AppColors.primary : Color.white.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 12, height: 12)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                
                // Option text
                Text(option.optionText)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.9))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                        AppColors.primary.opacity(0.15) :
                        Color.white.opacity(0.08)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? AppColors.primary : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
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
