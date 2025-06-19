import Foundation
import SwiftUI
import Combine

// MARK: - Refactored Auth View Model
@MainActor
final class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoggedIn: Bool = false
    @Published var isQuizCompleted: Bool = false
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    // User Info
    @Published var currentUser: User?
    
    // Login Form
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var emailError: String?
    
    // Register Form
    @Published var registerForm = RegisterFormData()
    @Published var registeredUserID: Int?
    
    // Navigation
    @Published var showRegister: Bool = false
    @Published var showRegisterComplete: Bool = false
    @Published var shouldShowQuiz: Bool = false
    
    // MARK: - Private Properties
    private let authService: AuthServiceProtocol
    private let quizService: QuizServiceProtocol
    private let apiClient = APIClient.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var isEmailValid: Bool {
        Validators.isValidEmail(email)
    }
    
    var isRegisterFormValid: Bool {
        registerForm.isValid
    }
    
    // Legacy support
    var accessToken: String? {
        TokenManager.shared.accessToken
    }
    
    var refreshToken: String? {
        TokenManager.shared.refreshToken
    }
    
    // Legacy properties for compatibility
    var newUserEmail: String {
        get { registerForm.email }
        set { registerForm.email = newValue }
    }
    
    var newUserFullName: String {
        get { registerForm.fullName }
        set { registerForm.fullName = newValue }
    }
    
    var newUserUsername: String {
        get { registerForm.username }
        set { registerForm.username = newValue }
    }
    
    var newUserPhoneNumber: String {
        get { registerForm.phoneNumber }
        set { registerForm.phoneNumber = newValue }
    }
    
    var newUserPassword: String {
        get { registerForm.password }
        set { registerForm.password = newValue }
    }
    
    // MARK: - Initialization
    init(authService: AuthServiceProtocol = AuthService.shared,
         quizService: QuizServiceProtocol = QuizService.shared) {
        self.authService = authService
        self.quizService = quizService
        
        // APIClient'a AuthManager olarak kendini set et
        apiClient.setAuthManager(self)
        
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Bind to auth service
        authService.isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuth in
                self?.isLoggedIn = isAuth
            }
            .store(in: &cancellables)
        
        authService.currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
                self?.isQuizCompleted = user?.isQuizCompleted ?? false
            }
            .store(in: &cancellables)
        
        // Bind to quiz service
        quizService.quizStatusPublisher
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] status in
                self?.isQuizCompleted = status.quizCompleted
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Authentication Methods
    func login() {
        clearError()
        
        // Validate
        guard validateLoginForm() else { return }
        
        isLoading = true
        
        Task {
            do {
                let user = try await authService.login(email: email, password: password)
                
                // Clear form
                email = ""
                password = ""
                
                // Check quiz status
                await checkQuizStatus()
                
            } catch {
                handleError(error)
            }
            
            isLoading = false
        }
    }
    
    func registerUser() async {
        clearError()
        
        // Validate
        guard registerForm.isValid else {
            emailError = "Lütfen tüm alanları doldurun"
            return
        }
        
        isLoading = true
        
        do {
            let request = RegisterRequest(
                email: registerForm.email,
                password: registerForm.password,
                username: registerForm.username,
                fullName: registerForm.fullName,
                phoneNumber: registerForm.phoneNumber
            )
            
            // Doğrudan APIClient kullan
            let response: AuthResponse = try await apiClient.request(
                AuthEndpoint.register(request)
            )
            
            if response.success, let userId = response.userId {
                registeredUserID = userId
            } else {
                throw AuthError.registrationFailed(response.error ?? "Kayıt başarısız")
            }
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func verifyEmail(otpCode: String) async -> Bool {
        guard let userId = registeredUserID else { return false }
        
        isLoading = true
        
        do {
            let response: MessageResponse = try await apiClient.request(
                AuthEndpoint.verifyEmail(userId: userId, code: otpCode)
            )
            
            isLoading = false
            return response.success
        } catch {
            handleError(error)
            isLoading = false
            return false
        }
    }
    
    func resendOTP() async {
        guard let userId = registeredUserID else { return }
        
        do {
            let _: MessageResponse = try await apiClient.request(
                AuthEndpoint.resendOTP(userId: userId)
            )
        } catch {
            // Silent fail
            print("Resend OTP error: \(error)")
        }
    }
    
    func logout() {
        Task {
            isLoading = true
            
            do {
                try await authService.logout()
                
                // Clear forms
                clearForms()
                
            } catch {
                print("Logout error: \(error)")
            }
            
            isLoading = false
        }
    }
    
    func checkQuizStatus() async {
        do {
            let response: QuizStatusResponse = try await apiClient.request(
                QuizEndpoint.getStatus
            )
            
            if response.success {
                isQuizCompleted = response.data.quizCompleted
            }
        } catch {
            print("Quiz status check error: \(error)")
        }
    }
    
    // MARK: - Token Management (Legacy support)
    func refreshAccessToken(refreshToken: String) async -> Bool {
        return await authService.refreshTokenIfNeeded()
    }
    
    func saveTokens(accessToken: String, refreshToken: String) {
        Task {
            await TokenManager.shared.saveTokens(
                accessToken: accessToken,
                refreshToken: refreshToken
            )
        }
    }
    
    // MARK: - Private Methods
    private func validateLoginForm() -> Bool {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            emailError = "E-posta boş bırakılamaz"
            return false
        }
        
        guard isEmailValid else {
            emailError = "Geçerli bir e-posta adresi girin"
            return false
        }
        
        guard !password.trimmingCharacters(in: .whitespaces).isEmpty else {
            emailError = "Şifre boş bırakılamaz"
            return false
        }
        
        return true
    }
    
    private func clearForms() {
        email = ""
        password = ""
        registerForm = RegisterFormData()
        emailError = nil
        registeredUserID = nil
    }
    
    private func clearError() {
        emailError = nil
        showError = false
        errorMessage = ""
    }
    
    private func handleError(_ error: Error) {
        if let authError = error as? AuthError {
            emailError = authError.errorDescription
        } else if let apiError = error as? APIError {
            emailError = apiError.errorDescription
        } else {
            emailError = error.localizedDescription
        }
        
        errorMessage = emailError ?? "Bir hata oluştu"
        showError = true
    }
}

// MARK: - Register Form Data
struct RegisterFormData {
    var email: String = ""
    var fullName: String = ""
    var username: String = ""
    var phoneNumber: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    
    var isValid: Bool {
        !email.isEmpty &&
        !fullName.isEmpty &&
        !username.isEmpty &&
        !phoneNumber.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        Validators.isValidEmail(email) &&
        password.count >= 8
    }
}

// MARK: - Extensions for Compatibility
extension AuthViewModel: AuthManagerProtocol {
    func refreshTokenIfNeeded() async -> Bool {
        return await authService.refreshTokenIfNeeded()
    }
    
    func logout() async {
        isLoading = true
        
        do {
            try await authService.logout()
            
            await MainActor.run {
                clearForms()
            }
            
        } catch {
            print("Logout error: \(error)")
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
}
