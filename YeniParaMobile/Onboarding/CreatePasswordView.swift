import SwiftUI

struct CreatePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authVM: AuthViewModel
    @FocusState private var focusedField: Field?
    @State private var keyboardHeight: CGFloat = 0
    
    private enum Field: Hashable {
        case password, confirmPassword
    }
    
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isConfirmVisible: Bool = false
    @State private var acceptedTerms: Bool = false
    @State private var navigateToOTP = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showKVKK = false
    
    private var passwordValidations: [ValidationItem] {
        [
            ValidationItem(
                title: "En az 8 karakter",
                isValid: password.count >= 8,
                icon: "checkmark.circle.fill"
            ),
            ValidationItem(
                title: "En az 1 büyük harf",
                isValid: password.range(of: "[A-Z]", options: .regularExpression) != nil,
                icon: "checkmark.circle.fill"
            ),
            ValidationItem(
                title: "En az 1 rakam",
                isValid: password.range(of: "[0-9]", options: .regularExpression) != nil,
                icon: "checkmark.circle.fill"
            )
        ]
    }
    
    private var isValidPassword: Bool {
        passwordValidations.allSatisfy { $0.isValid }
    }
    
    private var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }
    
    private var canSubmit: Bool {
        isValidPassword && passwordsMatch && acceptedTerms
    }
    
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
                // Navigation Bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Geri")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Progress indicator
                    HStack(spacing: 6) {
                        ForEach(0..<3) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(index <= 1 ? AppColors.primary : Color.white.opacity(0.3))
                                .frame(width: 24, height: 4)
                        }
                    }
                    
                    Spacer()
                    
                    // Invisible spacer for balance
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("Geri")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.clear)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 20) {
                            Image("logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 64, height: 64)
                            
                            VStack(spacing: 8) {
                                Text("Şifre oluşturun")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("Güvenli bir şifre belirleyin")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(.bottom, 32)
                        
                        // Form Fields
                        VStack(spacing: 20) {
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
                                            TextField("En az 8 karakter", text: $password)
                                        } else {
                                            SecureField("En az 8 karakter", text: $password)
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
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                            
                            // Password Validations - Yan yana
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
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
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
                            
                            // Terms and Conditions
                            HStack(alignment: .top, spacing: 12) {
                                Button {
                                    if !acceptedTerms {
                                        // Checkbox'a tıklandığında KVKK sayfasını aç
                                        showKVKK = true
                                    } else {
                                        // Zaten kabul edilmişse, kabul edilmemiş yap
                                        acceptedTerms = false
                                    }
                                } label: {
                                    Image(systemName: acceptedTerms ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 20))
                                        .foregroundColor(acceptedTerms ? AppColors.primary : Color.white.opacity(0.3))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Button {
                                        showKVKK = true
                                    } label: {
                                        Text("Kullanıcı sözleşmesini ve KVKK aydınlatma metnini kabul ediyorum.")
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.8))
                                            .multilineTextAlignment(.leading)
                                            .underline()
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 24)
                        
                        // Error message
                        if showError {
                            Text(errorMessage)
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.error)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .padding(.top, 12)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Bottom spacing - Klavye açıkken buton görünmesi için
                        Spacer(minLength: keyboardHeight > 0 ? keyboardHeight + 100 : 100)
                    }
                }
                
                // Bottom Button - Klavye açıksa gizle
                if keyboardHeight == 0 {
                    VStack(spacing: 16) {
                        Button(action: {
                            Task {
                                await registerUser()
                            }
                        }) {
                            HStack {
                                if authVM.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Tamamla")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                            }
                            .foregroundColor(canSubmit && !authVM.isLoading ? .black : .white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        canSubmit && !authVM.isLoading ?
                                        AppColors.primary :
                                        Color.white.opacity(0.15)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        canSubmit && !authVM.isLoading ?
                                        Color.clear :
                                        Color.white.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                            .animation(.easeInOut(duration: 0.2), value: canSubmit)
                        }
                        .disabled(!canSubmit || authVM.isLoading)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 28/255, green: 29/255, blue: 36/255).opacity(0),
                                Color(red: 28/255, green: 29/255, blue: 36/255)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 120)
                        .offset(y: -60)
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToOTP) {
            EmailVerificationView(authVM: authVM)
        }
        .sheet(isPresented: $showKVKK) {
            NavigationView {
                KVKKView(onAccept: {
                    acceptedTerms = true
                    showKVKK = false
                })
            }
        }
        .onTapGesture {
            focusedField = nil
        }
        .animation(.easeInOut(duration: 0.2), value: showError)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            withAnimation(.easeOut(duration: 0.25)) {
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
            }
        }
        .animation(.easeInOut(duration: 0.25), value: keyboardHeight)
    }
    
    private func registerUser() async {
        await MainActor.run {
            showError = false
            errorMessage = ""
        }
        
        authVM.newUserPassword = password
        
        await authVM.registerUser()
        
        await MainActor.run {
            if authVM.registeredUserID != nil {
                // Debug logging removed for production
                navigateToOTP = true
            } else {
                // Debug logging removed for production
                showError = true
                errorMessage = authVM.emailError ?? "Kayıt işlemi başarısız. Lütfen tekrar deneyin."
            }
        }
    }
}

struct ValidationItem {
    let title: String
    let isValid: Bool
    let icon: String
}

struct CreatePasswordView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CreatePasswordView(authVM: AuthViewModel())
        }
        .preferredColorScheme(.dark)
    }
}
