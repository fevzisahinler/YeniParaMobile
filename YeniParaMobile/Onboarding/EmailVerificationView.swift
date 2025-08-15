import SwiftUI

struct EmailVerificationView: View {
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var authVM: AuthViewModel
    
    @State private var code: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusIndex: Int?
    
    @State private var timeRemaining: Int = 60
    @State private var resendAvailable: Bool = false
    @State private var showRegisterComplete: Bool = false

    private var isComplete: Bool {
        code.allSatisfy { $0.count == 1 && $0.first!.isNumber }
    }

    var body: some View {
        ZStack {
            Color(red: 28/255, green: 29/255, blue: 36/255)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)

                Text("E‑posta adresinizi doğrulayın")
                    .font(.largeTitle).bold()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                if authVM.registeredUserID != nil {
                    VStack(spacing: 4) {
                        Text(authVM.newUserEmail)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Text("adresine gönderilen doğrulama kodunu girin")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                HStack(spacing: 12) {
                    ForEach(0..<6) { i in
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(focusIndex == i ? Color(red: 143/255, green: 217/255, blue: 83/255) : Color.white.opacity(0.3), lineWidth: 2)
                                .frame(width: 50, height: 60)
                            
                            TextField("", text: $code[i])
                                .keyboardType(.numberPad)
                                .textFieldStyle(PlainTextFieldStyle())
                                .multilineTextAlignment(.center)
                                .font(.title)
                                .fontWeight(.semibold)
                                .frame(width: 50, height: 60)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .focused($focusIndex, equals: i)
                                .onChange(of: code[i]) { oldValue, newValue in
                                    // Sadece sayıları kabul et
                                    let filtered = newValue.filter { $0.isNumber }
                                    
                                    if filtered.count > 1 {
                                        // Birden fazla karakter girilmişse, sadece ilkini al
                                        code[i] = String(filtered.prefix(1))
                                    } else {
                                        code[i] = filtered
                                    }
                                    
                                    // Eğer bir sayı girildiyse, bir sonraki kutuya geç
                                    if code[i].count == 1 && i < 5 {
                                        focusIndex = i + 1
                                    }
                                    
                                    // Eğer silindiyse ve boşsa, bir önceki kutuya geç
                                    if code[i].isEmpty && i > 0 {
                                        focusIndex = i - 1
                                    }
                                }
                                .onSubmit {
                                    // Enter'a basıldığında bir sonraki kutuya geç
                                    if i < 5 {
                                        focusIndex = i + 1
                                    }
                                }
                        }
                    }
                }
                .onTapGesture {
                    // İlk boş kutuya focus et
                    if let firstEmpty = code.firstIndex(where: { $0.isEmpty }) {
                        focusIndex = firstEmpty
                    }
                }

                PrimaryButton(
                    title: "Doğrula",
                    action: {
                        Task {
                            let otpString = code.joined()
                            let success = await authVM.verifyEmail(otpCode: otpString)
                            if success {
                                showRegisterComplete = true
                            }
                        }
                    },
                    background: Color(red: 143/255, green: 217/255, blue: 83/255),
                    foreground: .white
                )
                .disabled(!isComplete)
                .frame(height: 48)
                .padding(.horizontal, 24)

                if !resendAvailable {
                    Text("Yeniden göndermek için \(timeRemaining) saniye")
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    Button {
                        Task {
                            await authVM.resendOTP()
                            timeRemaining = 60
                            resendAvailable = false
                        }
                    } label: {
                        Text("Kodu yeniden gönder")
                            .underline()
                            .foregroundColor(.white)
                    }
                }

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            focusIndex = 0
            startTimer()
        }
        .navigationDestination(isPresented: $showRegisterComplete) {
            RegisterCompleteView(authVM: authVM)
        }
    }

    private func startTimer() {
        timeRemaining = 60
        resendAvailable = false

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer.invalidate()
                resendAvailable = true
            }
        }
    }
}

struct EmailVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            EmailVerificationView(authVM: AuthViewModel())
        }
    }
}
