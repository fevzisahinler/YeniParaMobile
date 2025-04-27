import SwiftUI

struct RegisterView: View {
    @State private var goToProfileInfo = false
    @ObservedObject var authVM: AuthViewModel
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

                        VStack(alignment: .leading, spacing: 4) {
                            Text("E‑Posta")
                                .font(.footnote)
                                .foregroundColor(Color.white.opacity(0.7))
                            
                            InputField(
                                text: $authVM.newUserEmail,
                                placeholder: ""
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        NavigationLink(
                            destination: ProfileInfoView(authVM: authVM),
                            isActive: $goToProfileInfo
                        ) { EmptyView() }

                        PrimaryButton(
                            title: "Kayıt Ol",
                            action: {
                                if Validators.isValidEmail(authVM.newUserEmail) {
                                    goToProfileInfo = true
                                } else {
                                    authVM.emailError = "Geçerli bir e‑posta girin."
                                }
                            },
                            background: Color(red: 111/255, green: 170/255, blue: 12/255),
                            foreground: .white
                        )
                        .disabled(!Validators.isValidEmail(authVM.newUserEmail))
                        .frame(height: 48)
                        .padding(.horizontal, 24)

                        VStack(spacing: 12) {
                            Text("Hesabınız var mı?")
                                .font(.callout)
                                .foregroundColor(Color.white.opacity(0.7))
                            Button(action: {
                                authVM.showRegister = false
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
            }
        }
    }

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView(authVM: AuthViewModel())
    }
}
