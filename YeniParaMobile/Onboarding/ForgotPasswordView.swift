import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var navigateToReset = false
    @FocusState private var isEmailFocused: Bool
    
    private var isEmailValid: Bool {
        Validators.isValidEmail(email)
    }
    
    var body: some View {
        NavigationStack {
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
                                    Text("Şifrenizi mi unuttunuz?")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Text("E-posta adresinizi girin, size şifre\nsıfırlama kodu gönderelim")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.8))
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(4)
                                }
                            }
                            .padding(.bottom, 32)
                            
                            // Form Section
                            VStack(spacing: 8) {
                                // Email Field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("E-posta Adresi")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    HStack {
                                        Image(systemName: "envelope")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white.opacity(0.5))
                                        
                                        TextField("E-postanızı girin", text: $email)
                                            .keyboardType(.emailAddress)
                                            .autocapitalization(.none)
                                            .textContentType(.emailAddress)
                                            .foregroundColor(.white)
                                            .focused($isEmailFocused)
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
                                
                                // Error Message
                                if showError && !errorMessage.isEmpty {
                                    Text(errorMessage)
                                        .font(.system(size: 13))
                                        .foregroundColor(AppColors.error)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 0)
                                        .padding(.top, 4)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            // Success Message
                            if showSuccess {
                                VStack(spacing: 16) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(AppColors.primary)
                                    
                                    Text("Kod e-posta adresinize gönderildi!")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                                        .scaleEffect(1.2)
                                }
                                .padding(.vertical, 40)
                                .transition(.scale.combined(with: .opacity))
                            }
                            
                            Spacer().frame(height: 40)
                            
                            // Submit Button
                            Button(action: {
                                Task {
                                    await sendResetCode()
                                }
                            }) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Kod Gönder")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                }
                                .foregroundColor(isEmailValid && !isLoading ? .black : .white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            isEmailValid && !isLoading ?
                                            AppColors.primary :
                                            Color.white.opacity(0.15)
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            isEmailValid && !isLoading ?
                                            Color.clear :
                                            Color.white.opacity(0.2),
                                            lineWidth: 1
                                        )
                                )
                                .animation(.easeInOut(duration: 0.2), value: isEmailValid)
                            }
                            .disabled(!isEmailValid || isLoading || showSuccess)
                            .padding(.horizontal, 24)
                            
                            // Back to Login Link
                            Button {
                                dismiss()
                            } label: {
                                Text("Giriş sayfasına dön")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(AppColors.primary)
                            }
                            .padding(.top, 24)
                            
                            Spacer()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToReset) {
                ResetPasswordView(email: email)
            }
        }
        .onTapGesture {
            isEmailFocused = false
        }
        .animation(.easeInOut(duration: 0.2), value: showError)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showSuccess)
    }
    
    private func sendResetCode() async {
        await MainActor.run {
            showError = false
            showSuccess = false
            isLoading = true
        }
        
        do {
            guard let url = URL(string: "http://192.168.1.210:4000/api/v1/auth/forgot-password") else {
                throw ForgotPasswordError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = ["email": email]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ForgotPasswordError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    
                    await MainActor.run {
                        isLoading = false
                        showSuccess = true
                        
                        // Navigate after short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            navigateToReset = true
                        }
                    }
                } else {
                    throw ForgotPasswordError.invalidResponse
                }
            } else {
                // Handle error response
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? String {
                    throw ForgotPasswordError.serverError(error)
                } else {
                    throw ForgotPasswordError.serverError("Bir hata oluştu")
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
                showError = true
                
                if let forgotError = error as? ForgotPasswordError {
                    switch forgotError {
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
}

enum ForgotPasswordError: Error {
    case invalidURL
    case invalidResponse
    case serverError(String)
}

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
            .preferredColorScheme(.dark)
    }
}

