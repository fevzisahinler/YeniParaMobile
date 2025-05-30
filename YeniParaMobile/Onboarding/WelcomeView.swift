import SwiftUI

struct WelcomeView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var isPasswordVisible: Bool = false
    
    var body: some View {
        ZStack {
            Color(red: 28/255, green: 29/255, blue: 36/255).ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer().frame(height: 40)
                
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                
                Text("Hoş geldiniz")
                    .font(.largeTitle).bold()
                    .foregroundColor(.white)
                
                Text("Hesabınıza giriş yapın.")
                    .font(.subheadline)
                    .foregroundColor(Color.white.opacity(0.7))
                
                VStack(spacing: 16) {
                    SocialButton(
                        imageName: "google-logo",
                        title: "Google ile devam et",
                        action: authVM.signInWithGoogle
                    )
                }
                .padding(.horizontal, 24)
                
                HStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 1)
                    Text("veya")
                        .font(.footnote)
                        .foregroundColor(Color.white.opacity(0.7))
                        .padding(.horizontal, 8)
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.horizontal, 24)
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("E‑Posta")
                            .font(.footnote)
                            .foregroundColor(Color.white.opacity(0.7))
                        InputField(
                            text: $authVM.email,
                            placeholder: ""
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Şifre")
                            .font(.footnote)
                            .foregroundColor(Color.white.opacity(0.7))
                        
                        HStack {
                            Group {
                                if isPasswordVisible {
                                    TextField("Şifrenizi girin", text: $authVM.password)
                                } else {
                                    SecureField("Şifrenizi girin", text: $authVM.password)
                                }
                            }
                            .autocapitalization(.none)
                            .textContentType(.password)
                            .foregroundColor(.white)
                            
                            Button {
                                isPasswordVisible.toggle()
                            } label: {
                                Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.6), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                // Hata mesajı
                if let error = authVM.emailError {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(Color(red: 218/255, green: 60/255, blue: 46/255))
                        .padding(.horizontal, 24)
                        .multilineTextAlignment(.center)
                }
                
                PrimaryButton(
                    title: authVM.isLoading ? "Giriş yapılıyor..." : "Giriş Yap",
                    action: { authVM.login() },
                    background: authVM.isEmailValid && !authVM.password.isEmpty ?
                        Color(red: 218/255, green: 60/255, blue: 46/255) :
                        Color.gray,
                    foreground: .white
                )
                .disabled(!authVM.isEmailValid || authVM.password.isEmpty || authVM.isLoading)
                .frame(height: 48)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                VStack(spacing: 12) {
                    Text("Hesabınız yok mu?")
                        .font(.callout)
                        .foregroundColor(Color.white.opacity(0.7))
                    Button(action: {
                        authVM.showRegister = true
                    }) {
                        Text("Kayıt Ol")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 143/255, green: 217/255, blue: 83/255))
                            .underline()
                    }
                }
                .padding(.bottom, 24)
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $authVM.showRegister) {
            RegisterView(authVM: authVM)
        }
        .fullScreenCover(isPresented: $authVM.showPhoneNumberEntry) {
            PhoneNumberEntryView { phoneEntered in
                Task {
                    guard let userID = authVM.googleProfileIncompleteUserID else { return }
                    let success = await authVM.completeProfile(
                        userID: userID,
                        phoneNumber: phoneEntered
                    )
                    if success {
                        authVM.showPhoneNumberEntry = false
                        authVM.showRegisterComplete = true
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $authVM.showRegisterComplete) {
            RegisterCompleteView(authVM: authVM)
        }
    }
}
