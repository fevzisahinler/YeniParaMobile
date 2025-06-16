import SwiftUI

struct RegisterView: View {
    @State private var goToProfileInfo = false
    @ObservedObject var authVM: AuthViewModel
    @FocusState private var isEmailFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    private var isEmailValid: Bool {
        Validators.isValidEmail(authVM.newUserEmail)
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
                    
                    // Top Section with Logo
                    VStack(spacing: 20) {
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 72, height: 72)
                            .padding(.top, 20)
                        
                        VStack(spacing: 8) {
                            Text("Hesap oluşturun")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("E-posta adresiniz ile kaydolun")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.bottom, 32)
                    
                    // Form Section
                    VStack(spacing: 8) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("E-posta")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            HStack {
                                Image(systemName: "envelope")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.5))
                                
                                TextField("E-postanızı girin", text: $authVM.newUserEmail)
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
                        if let error = authVM.emailError {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.error)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 0)
                                .padding(.top, 4)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    NavigationLink(
                        destination: ProfileInfoView(authVM: authVM),
                        isActive: $goToProfileInfo
                    ) { EmptyView() }
                    
                    // Reduced spacing
                    Spacer().frame(height: 24)
                    
                    // Register Button
                    Button(action: {
                        authVM.emailError = nil
                        if isEmailValid {
                            goToProfileInfo = true
                        } else {
                            authVM.emailError = "Geçerli bir e-posta adresi girin"
                        }
                    }) {
                        Text("Kayıt Ol")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(isEmailValid ? .black : .white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        isEmailValid ?
                                        AppColors.primary :
                                        Color.white.opacity(0.15)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        isEmailValid ?
                                        Color.clear :
                                        Color.white.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                            .animation(.easeInOut(duration: 0.2), value: isEmailValid)
                    }
                    .disabled(!isEmailValid)
                    .padding(.horizontal, 24)
                    
                    // Login Section - directly under Register button
                    HStack(spacing: 4) {
                        Text("Hesabınız var mı?")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Button {
                            authVM.showRegister = false
                            authVM.emailError = nil
                        } label: {
                            Text("Giriş Yap")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppColors.error)
                        }
                    }
                    .padding(.top, 24)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .onDisappear {
                authVM.emailError = nil
            }
            .onTapGesture {
                isEmailFocused = false
            }
        }
        .animation(.easeInOut(duration: 0.2), value: authVM.emailError)
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView(authVM: AuthViewModel())
    }
}
