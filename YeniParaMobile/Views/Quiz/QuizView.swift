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
            guard let url = URL(string: "http://localhost:4000/api/v1/quiz/submit") else {
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
            } else if quizVM.showResult && quizVM.quizResult != nil {
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
            } else {
                QuizContentView(quizVM: quizVM)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: quizVM.showResult)
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
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header with progress - Fixed height
                QuizHeaderView(
                    currentQuestion: quizVM.currentQuestionIndex + 1,
                    totalQuestions: quizVM.questions.count,
                    progress: quizVM.progressPercentage
                ) {
                    quizVM.previousQuestion()
                }
                .frame(height: 100) // Fixed header height
                
                // Question content with ScrollView
                if let question = quizVM.currentQuestion {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Question text section
                            VStack(spacing: 16) {
                                Text(question.questionText)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(AppColors.textPrimary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.horizontal, 24)
                            }
                            .padding(.top, 32)
                            .padding(.bottom, 40)
                            
                            // Options section
                            LazyVStack(spacing: 16) {
                                ForEach(question.options.sorted { $0.optionOrder < $1.optionOrder }) { option in
                                    QuizOptionButton(
                                        option: option,
                                        isSelected: quizVM.selectedOptionForCurrentQuestion == option.id,
                                        onTap: {
                                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                            impactFeedback.impactOccurred()
                                            quizVM.selectOption(option.id)
                                        }
                                    )
                                    .id("\(question.id)-\(option.id)")
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            // Bottom spacing to ensure content isn't hidden behind buttons
                            Spacer()
                                .frame(height: 120) // Space for navigation buttons
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .id(question.id) // Unique ID for question container
                }
                
                // Navigation buttons - Fixed at bottom
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
                .background(AppColors.background) // Ensure background matches
            }
        }
        .animation(.easeInOut(duration: 0.2), value: quizVM.selectedOptionForCurrentQuestion)
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
        .background(AppColors.background)
    }
}

// MARK: - Quiz Option Button - IMPROVED
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
                
                // Option text - IMPROVED TEXT HANDLING
                Text(option.optionText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true) // Allow proper text wrapping
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .leading) // Ensure full width alignment
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
        .transition(.opacity.combined(with: .scale))
    }
}

// MARK: - Quiz Navigation View - FIXED POSITIONING
struct QuizNavigationView: View {
    let canGoBack: Bool
    let canProceed: Bool
    let isLastQuestion: Bool
    let isLoading: Bool
    let onBack: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Divider line (optional)
            Rectangle()
                .fill(AppColors.cardBorder)
                .frame(height: 1)
                .opacity(0.3)
            
            HStack(spacing: 16) {
                // Back button - CONSISTENT SIZING
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
                        .frame(height: 50) // Fixed height for consistency
                        .background(AppColors.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.cardBorder, lineWidth: 1)
                        )
                    }
                } else {
                    // Invisible spacer to maintain layout
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                
                // Next/Submit button - CONSISTENT SIZING
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
                    .frame(height: 50) // Fixed height for consistency
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
            .padding(.vertical, 20)
        }
        .background(AppColors.background)
    }
}

// MARK: - Quiz Result View - ENHANCED UX/UI
struct QuizResultView: View {
    let result: QuizSubmitData?
    let onComplete: () -> Void
    
    @State private var showContent = false
    @State private var showSuccessAnimation = false
    
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
        case "growth":
            color = AppColors.secondary // Koyu yeşil
            icon = "chart.line.uptrend.xyaxis"
        case "aggressive":
            color = AppColors.primary // Ana yeşil
            icon = "chart.line.uptrend.xyaxis"
        default:
            color = AppColors.primary
            icon = "person.crop.circle"
        }
        
        return (title, description, color, icon)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with subtle gradient
                LinearGradient(
                    colors: [
                        AppColors.background,
                        AppColors.background.opacity(0.9),
                        profileTypeInfo.color.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Scrollable content
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            Spacer(minLength: 40)
                            
                            // Success Animation with Confetti Effect
                            if showContent {
                                VStack(spacing: 20) {
                                    // Animated Success Icon
                                    ZStack {
                                        // Outer glow ring
                                        Circle()
                                            .stroke(profileTypeInfo.color.opacity(0.3), lineWidth: 2)
                                            .frame(width: 130, height: 130)
                                            .scaleEffect(showSuccessAnimation ? 1.2 : 1.0)
                                            .opacity(showSuccessAnimation ? 0 : 1)
                                            .animation(.easeOut(duration: 1.2).delay(0.5), value: showSuccessAnimation)
                                        
                                        // Main circle with gradient
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [profileTypeInfo.color, profileTypeInfo.color.opacity(0.8)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 110, height: 110)
                                            .scaleEffect(showContent ? 1.0 : 0.3)
                                            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: showContent)
                                            .shadow(color: profileTypeInfo.color.opacity(0.4), radius: 20, x: 0, y: 10)
                                        
                                        // Icon with bounce animation
                                        Image(systemName: profileTypeInfo.icon)
                                            .font(.system(size: 36, weight: .bold))
                                            .foregroundColor(.white)
                                            .scaleEffect(showContent ? 1.0 : 0.3)
                                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: showContent)
                                    }
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                            showSuccessAnimation = true
                                        }
                                    }
                                    
                                    // Result Text with Staggered Animation
                                    VStack(spacing: 12) {
                                        Text("🎉 Tebrikler!")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(profileTypeInfo.color)
                                            .opacity(showContent ? 1 : 0)
                                            .animation(.easeInOut(duration: 0.6).delay(0.8), value: showContent)
                                        
                                        Text("Senin yatırımcı tipin:")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(AppColors.textSecondary)
                                            .opacity(showContent ? 1 : 0)
                                            .animation(.easeInOut(duration: 0.6).delay(1.0), value: showContent)
                                        
                                        Text(profileTypeInfo.title)
                                            .font(.system(size: 28, weight: .bold, design: .rounded))
                                            .foregroundColor(AppColors.textPrimary)
                                            .multilineTextAlignment(.center)
                                            .opacity(showContent ? 1 : 0)
                                            .animation(.easeInOut(duration: 0.6).delay(1.2), value: showContent)
                                    }
                                }
                            }
                            
                            // Description and Score with Cards
                            if showContent {
                                VStack(spacing: 16) {
                                    // Description Card
                                    VStack(spacing: 12) {
                                        Text(profileTypeInfo.description)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppColors.textSecondary)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(nil)
                                            .padding(.horizontal, 20)
                                        
                                        // Score Badge
                                        if let score = result?.totalPoints {
                                            HStack(spacing: 8) {
                                                Image(systemName: "star.fill")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(profileTypeInfo.color)
                                                
                                                Text("Toplam Puan: \(score)")
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(profileTypeInfo.color)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(profileTypeInfo.color.opacity(0.15))
                                                    .overlay(
                                                        Capsule()
                                                            .stroke(profileTypeInfo.color.opacity(0.3), lineWidth: 1)
                                                    )
                                            )
                                        }
                                    }
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(AppColors.cardBackground)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(AppColors.cardBorder, lineWidth: 1)
                                            )
                                    )
                                    .padding(.horizontal, 20)
                                    .opacity(showContent ? 1 : 0)
                                    .animation(.easeInOut(duration: 0.6).delay(1.4), value: showContent)
                                    
                                    // Portfolio Allocation Card
                                    if let profile = result?.investorProfile {
                                        VStack(spacing: 16) {
                                            HStack {
                                                Image(systemName: "chart.pie.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(profileTypeInfo.color)
                                                
                                                Text("Önerilen Portföy Dağılımı")
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(AppColors.textPrimary)
                                                
                                                Spacer()
                                            }
                                            
                                            HStack(spacing: 12) {
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
                                        .padding(.vertical, 16)
                                        .padding(.horizontal, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(AppColors.cardBackground)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(AppColors.cardBorder, lineWidth: 1)
                                                )
                                        )
                                        .padding(.horizontal, 20)
                                        .opacity(showContent ? 1 : 0)
                                        .animation(.easeInOut(duration: 0.6).delay(1.6), value: showContent)
                                    }
                                }
                            }
                            
                            // Recommendations Card
                            if showContent, let recommendations = result?.recommendations, !recommendations.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "lightbulb.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(profileTypeInfo.color)
                                        
                                        Text("Senin İçin Öneriler")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(AppColors.textPrimary)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    
                                    VStack(spacing: 8) {
                                        ForEach(Array(recommendations.enumerated()), id: \.element) { index, recommendation in
                                            HStack(alignment: .top, spacing: 10) {
                                                Circle()
                                                    .fill(profileTypeInfo.color)
                                                    .frame(width: 6, height: 6)
                                                    .padding(.top, 6)
                                                
                                                Text(recommendation)
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(AppColors.textSecondary)
                                                    .multilineTextAlignment(.leading)
                                                    .lineLimit(nil)
                                                
                                                Spacer()
                                            }
                                            .padding(.horizontal, 16)
                                            .opacity(showContent ? 1 : 0)
                                            .animation(.easeInOut(duration: 0.5).delay(1.8 + Double(index) * 0.1), value: showContent)
                                        }
                                    }
                                }
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(AppColors.cardBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(AppColors.cardBorder, lineWidth: 1)
                                        )
                                )
                                .padding(.horizontal, 20)
                            }
                            
                            // Bottom spacing for button
                            Spacer(minLength: 120) // Reduced from 140 to 120
                        }
                    }
                    
                    // Fixed bottom button with enhanced design
                    if showContent {
                        VStack(spacing: 0) {
                            // Subtle gradient overlay
                            LinearGradient(
                                colors: [
                                    AppColors.background.opacity(0),
                                    AppColors.background.opacity(0.8),
                                    AppColors.background
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 30)
                            
                            // Action Button
                            Button(action: {
                                print("🔥 Uygulamaya Geç button tapped!")
                                onComplete()
                            }) {
                                HStack(spacing: 12) {
                                    Text("Uygulamaya Geç")
                                        .font(.system(size: 18, weight: .bold))
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(
                                        colors: [AppColors.primary, AppColors.secondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: AppColors.primary.opacity(0.4), radius: 12, x: 0, y: 6)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 35) // Reduced from 50 to 35
                            .background(AppColors.background)
                            .opacity(showContent ? 1 : 0)
                            .animation(.easeInOut(duration: 0.6).delay(2.2), value: showContent)
                        }
                    }
                }
            }
        }
        .onAppear {
            showContent = true
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
