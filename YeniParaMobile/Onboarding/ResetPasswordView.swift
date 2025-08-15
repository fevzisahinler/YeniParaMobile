import SwiftUI

// MARK: - Error Types
enum PasswordResetError: Error {
    case invalidURL
    case invalidResponse
    case serverError(String)
}

struct ResetPasswordView: View {
    let email: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var code: [String] = Array(repeating: "", count: 6)
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isConfirmVisible: Bool = false
    
    @FocusState private var focusIndex: Int?
    @FocusState private var focusedField: Field?
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var shouldDismissToRoot = false
    
    @State private var timeRemaining: Int = 60
    @State private var resendAvailable: Bool = false
    @State private var timer: Timer?
    
    private enum Field: Hashable {
        case password, confirmPassword
    }
    
    private var isCodeComplete: Bool {
        code.allSatisfy { $0.count == 1 && $0.first!.isNumber }
    }
    
    private var passwordValidations: [ValidationItem] {
        [
            ValidationItem(
                title: "En az 8 karakter",
                isValid: newPassword.count >= 8,
                icon: "checkmark.circle.fill"
            ),
            ValidationItem(
                title: "En az 1 büyük harf",
                isValid: newPassword.range(of: "[A-Z]", options: .regularExpression) != nil,
                icon: "checkmark.circle.fill"
            ),
            ValidationItem(
                title: "En az 1 rakam",
                isValid: newPassword.range(of: "[0-9]", options: .regularExpression) != nil,
                icon: "checkmark.circle.fill"
            )
        ]
    }
    
    private var isValidPassword: Bool {
        passwordValidations.allSatisfy { $0.isValid }
    }
    
    private var passwordsMatch: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword
    }
    
    private var canSubmit: Bool {
        isCodeComplete && isValidPassword && passwordsMatch
    }
    
    @ViewBuilder
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 28/255, green: 29/255, blue: 36/255),
                Color(red: 20/255, green: 21/255, blue: 28/255)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    private var successPopupContent: some View {
        VStack(spacing: 24) {
            // Success icon
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(AppColors.primary)
            }
            
            // Success message
            VStack(spacing: 12) {
                Text("Başarılı!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Şifreniz başarıyla değiştirildi.\nGiriş sayfasına yönlendiriliyorsunuz...")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Loading indicator
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                .scaleEffect(1.0)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 30/255, green: 31/255, blue: 38/255))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(AppColors.primary.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    @ViewBuilder
    private var successPopup: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {}
            
            successPopupContent
                .scaleEffect(showSuccess ? 1.0 : 0.8)
                .opacity(showSuccess ? 1.0 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showSuccess)
        }
        .transition(.opacity)
    }
    
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
                // Close Button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header with Logo
                        VStack(spacing: 20) {
                            Image("logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 72, height: 72)
                                .padding(.top, 20)
                            
                            VStack(spacing: 8) {
                                Text("Yeni Şifre Belirleyin")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text(email)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(.bottom, 32)
                        
                        // OTP Code Section
                        VStack(spacing: 16) {
                            Text("Doğrulama Kodu")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 24)
                            
                            HStack(spacing: 8) {
                                ForEach(0..<6) { i in
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(focusIndex == i ? AppColors.primary : Color.white.opacity(0.3), lineWidth: 2)
                                            .frame(width: 45, height: 56)
                                        
                                        TextField("", text: $code[i])
                                            .keyboardType(.numberPad)
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .multilineTextAlignment(.center)
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                            .frame(width: 45, height: 56)
                                            .background(Color.white.opacity(0.08))
                                            .cornerRadius(12)
                                            .foregroundColor(.white)
                                            .focused($focusIndex, equals: i)
                                            .onChange(of: code[i]) { oldValue, newValue in
                                                handleCodeChange(at: i, newValue: newValue)
                                            }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            // Resend Code
                            if !resendAvailable {
                                Text("Yeniden göndermek için \(timeRemaining) saniye")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.6))
                            } else {
                                Button {
                                    Task {
                                        await resendCode()
                                    }
                                } label: {
                                    Text("Kodu yeniden gönder")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.primary)
                                        .underline()
                                }
                            }
                        }
                        .padding(.bottom, 32)
                        
                        // Password Fields
                        VStack(spacing: 20) {
                            // New Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Yeni Şifre")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                HStack {
                                    Image(systemName: "lock")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.5))
                                    
                                    Group {
                                        if isPasswordVisible {
                                            TextField("En az 8 karakter", text: $newPassword)
                                        } else {
                                            SecureField("En az 8 karakter", text: $newPassword)
                                        }
                                    }
                                    .textContentType(.newPassword)
                                    .foregroundColor(.white)
                                    .focused($focusedField, equals: .password)
                                    
                                    Button {
                                        isPasswordVisible.toggle()
                                    } label: {
                                        Image(systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.08))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    Color.white.opacity(0.2),
                                                    lineWidth: 1
                                                )
                                        )
                                )
                            }
                            
                            // Password Validations
                            HStack(spacing: 16) {
                                ForEach(passwordValidations, id: \.title) { validation in
                                    HStack(spacing: 6) {
                                        Image(systemName: validation.icon)
                                            .font(.system(size: 12))
                                            .foregroundColor(validation.isValid ? AppColors.primary : Color.white.opacity(0.3))
                                        
                                        Text(validation.title)
                                            .font(.system(size: 11))
                                            .foregroundColor(validation.isValid ? Color.white.opacity(0.8) : Color.white.opacity(0.4))
                                    }
                                    
                                    if validation.title != passwordValidations.last?.title {
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                            
                            // Confirm Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Şifre Tekrarı")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                HStack {
                                    Image(systemName: "lock")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.5))
                                    
                                    Group {
                                        if isConfirmVisible {
                                            TextField("Şifrenizi tekrar girin", text: $confirmPassword)
                                        } else {
                                            SecureField("Şifrenizi tekrar girin", text: $confirmPassword)
                                        }
                                    }
                                    .textContentType(.password)
                                    .foregroundColor(.white)
                                    .focused($focusedField, equals: .confirmPassword)
                                    
                                    Button {
                                        isConfirmVisible.toggle()
                                    } label: {
                                        Image(systemName: isConfirmVisible ? "eye.fill" : "eye.slash.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.08))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    Color.white.opacity(0.2),
                                                    lineWidth: 1
                                                )
                                        )
                                )
                                
                                // Password match indicator
                                if !confirmPassword.isEmpty {
                                    HStack(spacing: 8) {
                                        Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(passwordsMatch ? AppColors.primary : AppColors.error)
                                        
                                        Text(passwordsMatch ? "Şifreler eşleşiyor" : "Şifreler eşleşmiyor")
                                            .font(.system(size: 13))
                                            .foregroundColor(passwordsMatch ? AppColors.primary : AppColors.error)
                                    }
                                    .padding(.horizontal, 4)
                                    .padding(.top, 4)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Error Message
                        if showError {
                            Text(errorMessage)
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.error)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .padding(.top, 12)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        
                        Spacer().frame(height: 40)
                        
                        // Submit Button
                        Button(action: {
                            Task {
                                await resetPassword()
                            }
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Şifreyi Değiştir")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                            }
                            .foregroundColor(canSubmit && !isLoading ? .black : .white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        canSubmit && !isLoading ?
                                        AppColors.primary :
                                        Color.white.opacity(0.15)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        canSubmit && !isLoading ?
                                        Color.clear :
                                        Color.white.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                            .animation(.easeInOut(duration: 0.2), value: canSubmit)
                        }
                        .disabled(!canSubmit || isLoading || showSuccess)
                        .padding(.horizontal, 24)
                        
                        Spacer()
                    }
                }
        }
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
            mainContent
            
            if showSuccess {
                successPopup
            }
        }
        .navigationBarHidden(true)
        .onChange(of: shouldDismissToRoot) { oldValue, newValue in
            if newValue {
                // Dismiss both ForgotPasswordView and ResetPasswordView
                dismiss()
            }
        }
        .onAppear {
            focusIndex = 0
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onTapGesture {
            focusIndex = nil
            focusedField = nil
        }
        .animation(.easeInOut(duration: 0.2), value: showError)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showSuccess)
    }
    
    // MARK: - Helper Functions
    private func handleCodeChange(at index: Int, newValue: String) {
        let filtered = newValue.filter { $0.isNumber }
        
        if filtered.count > 1 {
            code[index] = String(filtered.prefix(1))
        } else {
            code[index] = filtered
        }
        
        if code[index].count == 1 && index < 5 {
            focusIndex = index + 1
        }
        
        if code[index].isEmpty && index > 0 {
            focusIndex = index - 1
        }
    }
    
    private func startTimer() {
        timeRemaining = 60
        resendAvailable = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                resendAvailable = true
            }
        }
    }
    
    private func resetPassword() async {
        await MainActor.run {
            showError = false
            showSuccess = false
            isLoading = true
        }
        
        do {
            guard let url = URL(string: "http://192.168.1.210:4000/api/v1/auth/reset-password") else {
                throw PasswordResetError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let otpCode = code.joined()
            let body: [String: Any] = [
                "email": email,
                "code": otpCode,
                "new_password": newPassword
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PasswordResetError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    
                    await MainActor.run {
                        isLoading = false
                        showSuccess = true
                        
                        // Clear any existing tokens and cache since password changed
                        authViewModel.logout()
                        APIService.shared.clearCache()
                        
                        // Dismiss all views to go back to root after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            shouldDismissToRoot = true
                        }
                    }
                } else {
                    throw PasswordResetError.invalidResponse
                }
            } else {
                // Handle error response
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? String {
                    throw PasswordResetError.serverError(error)
                } else {
                    throw PasswordResetError.serverError("Şifre sıfırlama başarısız")
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
                showError = true
                
                if let resetError = error as? PasswordResetError {
                    switch resetError {
                    case .invalidURL:
                        errorMessage = "Geçersiz sunucu adresi"
                    case .invalidResponse:
                        errorMessage = "Sunucu yanıtı alınamadı"
                    case .serverError(let message):
                        errorMessage = message
                    }
                } else {
                    errorMessage = "Bağlantı hatası. Lütfen tekrar deneyin."
                }
            }
        }
    }
    
    private func resendCode() async {
        guard resendAvailable else { return }
        
        do {
            guard let url = URL(string: "http://192.168.1.210:4000/api/v1/auth/resend-password-reset") else {
                throw PasswordResetError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = ["email": email]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PasswordResetError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                await MainActor.run {
                    // Reset timer
                    startTimer()
                    
                    // Clear code fields
                    code = Array(repeating: "", count: 6)
                    focusIndex = 0
                    
                    // Show brief success message
                    showError = false
                    errorMessage = ""
                }
            }
        } catch {
            await MainActor.run {
                showError = true
                errorMessage = "Kod gönderilemedi. Lütfen tekrar deneyin."
            }
        }
    }
}

struct ResetPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ResetPasswordView(email: "user@example.com")
            .preferredColorScheme(.dark)
    }
}
