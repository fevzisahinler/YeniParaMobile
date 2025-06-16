import SwiftUI

struct RegisterCompleteView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var isLoggingIn = false
    @State private var loginError: String?
    @State private var navigateToContentView = false
    
    var body: some View {
        ZStack {
            Color(red: 28/255, green: 29/255, blue: 36/255)
                .ignoresSafeArea()

            if isLoggingIn {
                // Loading state while auto-login
                VStack(spacing: 24) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                        .scaleEffect(1.5)
                    
                    Text("Giriş yapılıyor...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            } else {
                VStack(spacing: 24) {
                    Spacer().frame(height: 40)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(Color(red: 143/255, green: 217/255, blue: 83/255))

                    Text("Kayıt Başarıyla Tamamlandı")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Sizin için en uygun yatırım profilini belirlemek üzere birkaç sorumuz var.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Image("registercomplete")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 200, maxHeight: 200)

                    if let error = loginError {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(Color(red: 218/255, green: 60/255, blue: 46/255))
                            .padding(.horizontal, 24)
                            .multilineTextAlignment(.center)
                    }

                    PrimaryButton(
                        title: "Başla",
                        action: {
                            autoLogin()
                        },
                        background: Color(red: 143/255, green: 217/255, blue: 83/255),
                        foreground: .white
                    )
                    .frame(height: 48)
                    .padding(.horizontal, 24)
                    .disabled(isLoggingIn)

                    Text("Yaklaşık 1 dakikanızı alacak")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToContentView) {
            ContentView(authVM: authVM)
                .navigationBarBackButtonHidden(true)
        }
    }
    
    private func autoLogin() {
        // Check if we have user credentials
        guard !authVM.newUserEmail.isEmpty && !authVM.newUserPassword.isEmpty else {
            loginError = "Kullanıcı bilgileri bulunamadı."
            return
        }
        
        isLoggingIn = true
        loginError = nil
        
        // Set email and password for login
        authVM.email = authVM.newUserEmail
        authVM.password = authVM.newUserPassword
        
        // Perform login
        Task {
            await performLogin()
        }
    }
    
    private func performLogin() async {
        // Directly call performLogin instead of login() to avoid UI updates
        guard let url = URL(string: "http://192.168.1.210:4000/api/v1/auth/login") else {
            await MainActor.run {
                isLoggingIn = false
                loginError = "Sunucu bağlantısı hatası."
            }
            return
        }
        
        let requestBody: [String: Any] = [
            "email": authVM.email,
            "password": authVM.password
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    isLoggingIn = false
                    loginError = "Sunucu yanıt hatası."
                }
                return
            }
            
            if httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success,
                   let dataObj = json["data"] as? [String: Any] {
                    
                    guard let loginAccessToken = dataObj["access_token"] as? String,
                          let loginRefreshToken = dataObj["refresh_token"] as? String else {
                        await MainActor.run {
                            isLoggingIn = false
                            loginError = "Token bilgileri alınamadı."
                        }
                        return
                    }
                    
                    // User bilgilerini al
                    var quizCompleted = false
                    if let user = dataObj["user"] as? [String: Any],
                       let isQuizCompleted = user["is_quiz_completed"] as? Bool {
                        quizCompleted = isQuizCompleted
                    }
                    
                    await MainActor.run {
                        // Set tokens in AuthViewModel
                        authVM.accessToken = loginAccessToken
                        authVM.refreshToken = loginRefreshToken
                        authVM.isQuizCompleted = quizCompleted
                        authVM.isLoggedIn = true
                        
                        // Save tokens
                        authVM.saveTokens(accessToken: loginAccessToken, refreshToken: loginRefreshToken)
                        
                        isLoggingIn = false
                        
                        // Navigate to ContentView which will show the quiz
                        navigateToContentView = true
                    }
                } else {
                    await MainActor.run {
                        isLoggingIn = false
                        loginError = "Giriş başarısız."
                    }
                }
            } else {
                await MainActor.run {
                    isLoggingIn = false
                    loginError = "Giriş yapılamadı. Lütfen tekrar deneyin."
                }
            }
        } catch {
            await MainActor.run {
                isLoggingIn = false
                loginError = "Ağ bağlantısı hatası."
            }
        }
    }
}

struct RegisterCompleteView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterCompleteView(authVM: AuthViewModel())
    }
}
