import SwiftUI

struct RegisterView: View {
    @State private var goToProfileInfo = false
    @ObservedObject var authVM: AuthViewModel
    
    private var isEmailValid: Bool {
        Validators.isValidEmail(authVM.newUserEmail)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 28/255, green: 29/255, blue: 36/255)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer().frame(height: 40)

                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)

                    Text("Hesap oluşturun")
                        .font(.largeTitle).bold()
                        .foregroundColor(.white)
                    
                    Text("E‑Posta adresiniz ile kaydolun.")
                        .font(.subheadline)
                        .foregroundColor(Color.white.opacity(0.7))
                    
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("E‑Posta")
                            .font(.footnote)
                            .foregroundColor(Color.white.opacity(0.7))
                        
                        InputField(
                            text: $authVM.newUserEmail,
                            placeholder: ""
                        )
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                    }
                    .padding(.horizontal, 24)
                    
                    // Error message
                    if let error = authVM.emailError {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(Color(red: 218/255, green: 60/255, blue: 46/255))
                            .padding(.horizontal, 24)
                            .multilineTextAlignment(.center)
                    }
                    
                    NavigationLink(
                        destination: ProfileInfoView(authVM: authVM),
                        isActive: $goToProfileInfo
                    ) { EmptyView() }

                    PrimaryButton(
                        title: "Kayıt Ol",
                        action: {
                            authVM.emailError = nil
                            if isEmailValid {
                                goToProfileInfo = true
                            } else {
                                authVM.emailError = "Geçerli bir e‑posta girin."
                            }
                        },
                        background: isEmailValid ?
                            Color(red: 143/255, green: 217/255, blue: 83/255) :
                            Color.gray,
                        foreground: .white
                    )
                    .disabled(!isEmailValid)
                    .frame(height: 48)
                    .padding(.horizontal, 24)

                    VStack(spacing: 12) {
                        Text("Hesabınız var mı?")
                            .font(.callout)
                            .foregroundColor(Color.white.opacity(0.7))
                        Button(action: {
                            authVM.showRegister = false
                            // Clear any registration errors when going back
                            authVM.emailError = nil
                        }) {
                            Text("Giriş Yap")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(red: 218/255, green: 60/255, blue: 46/255))
                                .underline()
                        }
                    }
                    .padding(.bottom, 24)
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .onDisappear {
                // Clear error when leaving the view
                authVM.emailError = nil
            }
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView(authVM: AuthViewModel())
    }
}
