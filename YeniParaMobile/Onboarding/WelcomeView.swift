import SwiftUI

struct WelcomeView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var isPasswordVisible: Bool = false
    
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
                // Top Section with Logo
                VStack(spacing: 20) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .padding(.top, 60)
                    
                    VStack(spacing: 8) {
                        Text("Hoş geldiniz")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Hesabınıza giriş yapın")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.bottom, 48)
                
                // Form Section
                VStack(spacing: 16) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("E-posta")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack {
                            Image(systemName: "envelope")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.5))
                            
                            TextField("E-postanızı girin", text: $authVM.email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .textContentType(.emailAddress)
                                .foregroundColor(.white)
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
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Şifre")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack {
                            Image(systemName: "lock")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Group {
                                if isPasswordVisible {
                                    TextField("Şifrenizi girin", text: $authVM.password)
                                } else {
                                    SecureField("Şifrenizi girin", text: $authVM.password)
                                }
                            }
                            .textContentType(.password)
                            .foregroundColor(.white)
                            
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
                    
                    // Forgot Password - Reduced spacing
                    // Forgot Password - Reduced spacing
                                        HStack {
                                            Spacer()
                                            NavigationLink(destination: ForgotPasswordView()) {
                                                Text("Şifremi Unuttum")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(AppColors.primary)
                                            }
                                        }
                                        .padding(.top, -4) // Negative padding to reduce space
                    .padding(.top, -4) // Negative padding to reduce space
                }
                .padding(.horizontal, 24)
                
                // Error Message
                if let error = authVM.emailError {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                Spacer()
                
                // Bottom Section
                VStack(spacing: 0) {
                    // Login Button
                    Button(action: { authVM.login() }) {
                        HStack {
                            if authVM.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Giriş Yap")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .foregroundColor(authVM.isEmailValid && !authVM.password.isEmpty ? .white : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    authVM.isEmailValid && !authVM.password.isEmpty ?
                                    AppColors.error :
                                    Color.white.opacity(0.15)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    authVM.isEmailValid && !authVM.password.isEmpty ?
                                    Color.clear :
                                    Color.white.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                        .animation(.easeInOut(duration: 0.2), value: authVM.isEmailValid)
                        .animation(.easeInOut(duration: 0.2), value: authVM.password.isEmpty)
                    }
                    .disabled(!authVM.isEmailValid || authVM.password.isEmpty || authVM.isLoading)
                    .padding(.horizontal, 24)
                    
                    // Register Section - directly under Login button
                    HStack(spacing: 4) {
                        Text("Hesabınız yok mu?")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Button("Kayıt Ol") {
                            authVM.showRegister = true
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.primary)
                    }
                    .padding(.top, 24)
                    
                    Spacer()
                }
            }
        }
        .fullScreenCover(isPresented: $authVM.showRegister) {
            RegisterView(authVM: authVM)
        }
        .animation(.easeInOut(duration: 0.2), value: authVM.emailError)
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(authVM: AuthViewModel())
    }
}
