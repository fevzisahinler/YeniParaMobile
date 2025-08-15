import SwiftUI

struct ProfileInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authVM: AuthViewModel
    @FocusState private var focusedField: Field?
    @State private var keyboardHeight: CGFloat = 0
    
    private enum Field: Hashable {
        case fullName, username, phone
    }
    
    @State private var countryCode: String = "+90"
    
    private let countryOptions: [(code: String, flag: String)] = [
        ("+90", "🇹🇷"),
        ("+1",  "🇺🇸"),
        ("+44", "🇬🇧"),
        ("+49", "🇩🇪"),
        ("+33", "🇫🇷")
    ]
    
    private var isFormValid: Bool {
        let fullNameValid = !authVM.newUserFullName.trimmingCharacters(in: .whitespaces).isEmpty
        let usernameValid = !authVM.newUserUsername.trimmingCharacters(in: .whitespaces).isEmpty
        let phoneDigits = authVM.newUserPhoneNumber.filter(\.isNumber).count
        let phoneValid = phoneDigits == 10 || phoneDigits == 11 // 10 hane (0 olmadan) veya 11 hane (0 ile)
        
        return fullNameValid && usernameValid && phoneValid
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
                                .fill(index == 0 ? AppColors.primary : Color.white.opacity(0.3))
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
                                Text("Sizi Tanıyalım")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("Profilinizi oluşturmak için bilgilerinizi girin")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.bottom, 40)
                        
                        // Form Fields
                        VStack(spacing: 24) {
                            // Full Name Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("İsim & Soyisim")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                HStack {
                                    Image(systemName: "person")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.5))
                                    
                                    TextField("Ad Soyad", text: $authVM.newUserFullName)
                                        .textContentType(.name)
                                        .autocapitalization(.words)
                                        .foregroundColor(.white)
                                        .focused($focusedField, equals: .fullName)
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
                            
                            // Username Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Kullanıcı Adı")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                HStack {
                                    Image(systemName: "at")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.5))
                                    
                                    TextField("kullaniciadi", text: $authVM.newUserUsername)
                                        .textContentType(.username)
                                        .autocapitalization(.none)
                                        .foregroundColor(.white)
                                        .focused($focusedField, equals: .username)
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
                            
                            // Phone Number Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Telefon Numarası")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                HStack(spacing: 12) {
                                    // Country Code Selector
                                    Menu {
                                        ForEach(countryOptions, id: \.code) { option in
                                            Button {
                                                countryCode = option.code
                                            } label: {
                                                Text("\(option.flag) \(option.code)")
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Text(countryOptions.first { $0.code == countryCode }?.flag ?? "")
                                            Text(countryCode)
                                                .foregroundColor(.white)
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 12))
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                        .padding(.horizontal, 12)
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
                                    
                                    // Phone Input
                                    HStack {
                                        Image(systemName: "phone")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white.opacity(0.5))
                                        
                                        TextField("(555) 123 45 67", text: $authVM.newUserPhoneNumber)
                                            .keyboardType(.phonePad)
                                            .textContentType(.telephoneNumber)
                                            .foregroundColor(.white)
                                            .focused($focusedField, equals: .phone)
                                            .onChange(of: authVM.newUserPhoneNumber) { oldValue, newValue in
                                                formatPhoneNumber(newValue)
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
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Bottom spacing - Klavye açıkken buton görünmesi için
                        Spacer(minLength: keyboardHeight > 0 ? keyboardHeight + 100 : 100)
                    }
                }
                
                // Bottom Button - Klavye açıksa gizle
                if keyboardHeight == 0 {
                    VStack(spacing: 16) {
                        NavigationLink(destination: CreatePasswordView(authVM: authVM)) {
                            Text("İleri")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(isFormValid ? .black : .white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            isFormValid ?
                                            AppColors.primary :
                                            Color.white.opacity(0.15)
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            isFormValid ?
                                            Color.clear :
                                            Color.white.opacity(0.2),
                                            lineWidth: 1
                                        )
                                )
                        }
                        .disabled(!isFormValid)
                        .animation(.easeInOut(duration: 0.2), value: isFormValid)
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
        .onTapGesture {
            focusedField = nil
        }
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
    
    private func formatPhoneNumber(_ value: String) {
        var digits = value.filter(\.isNumber)
        if digits.count > 10 {
            digits = String(digits.prefix(10))
        }
        
        var result = ""
        for (i, c) in digits.enumerated() {
            if i == 0 { result += "(" }
            if i == 3 { result += ") " }
            if i == 6 { result += " " }
            if i == 8 { result += " " }
            result.append(c)
        }
        authVM.newUserPhoneNumber = result
    }
}

struct ProfileInfoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileInfoView(authVM: AuthViewModel())
        }
        .preferredColorScheme(.dark)
    }
}
