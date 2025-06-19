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
                        isLoading: isLoggingIn,
                        isEnabled: !isLoggingIn
                    )
                    .padding(.horizontal, 24)

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
        guard !authVM.registerForm.email.isEmpty && !authVM.registerForm.password.isEmpty else {
            loginError = "Kullanıcı bilgileri bulunamadı."
            return
        }
        
        isLoggingIn = true
        loginError = nil
        
        // Set email and password for login
        authVM.email = authVM.registerForm.email
        authVM.password = authVM.registerForm.password
        
        // Perform login
        authVM.login()
        
        // Navigate to content view after login completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if authVM.isLoggedIn {
                navigateToContentView = true
            } else {
                isLoggingIn = false
                loginError = authVM.emailError ?? "Giriş yapılamadı. Lütfen tekrar deneyin."
            }
        }
    }
}
