import SwiftUI

struct CreatePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isConfirmVisible: Bool = false
    @State private var acceptedTerms: Bool = false
    private var isValidPassword: Bool {
        password.count >= 8 &&
        password.range(of: "[A-Z]", options: .regularExpression) != nil &&
        password.range(of: "[0-9]", options: .regularExpression) != nil
    }
    private var canSubmit: Bool {
        isValidPassword && password == confirmPassword && acceptedTerms
    }
    var body: some View {
        ZStack {
            Color(red: 28/255, green: 29/255, blue: 36/255).ignoresSafeArea()
            VStack(spacing: 24) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.top, 12)
                .padding(.horizontal, 24)
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                Text("Şifre oluşturun")
                    .font(.largeTitle).bold()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Text("Güvenli bir şifre seçin\n(En az 8 karakter, 1 büyük harf ve 1 rakam içermelidir)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Şifre")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.7))
                        HStack {
                            Group {
                                if isPasswordVisible {
                                    TextField("••••••••", text: $password)
                                } else {
                                    SecureField("••••••••", text: $password)
                                }
                            }
                            .autocapitalization(.none)
                            .textContentType(.newPassword)
                            .foregroundColor(.white)
                            Button { isPasswordVisible.toggle() } label: {
                                Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Şifrenizi tekrar giriniz")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.7))
                        HStack {
                            Group {
                                if isConfirmVisible {
                                    TextField("••••••••", text: $confirmPassword)
                                } else {
                                    SecureField("••••••••", text: $confirmPassword)
                                }
                            }
                            .autocapitalization(.none)
                            .textContentType(.password)
                            .foregroundColor(.white)
                            Button { isConfirmVisible.toggle() } label: {
                                Image(systemName: isConfirmVisible ? "eye" : "eye.slash")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                    HStack(alignment: .top, spacing: 8) {
                        Button { acceptedTerms.toggle() } label: {
                            Image(systemName: acceptedTerms ? "checkmark.square.fill" : "square")
                                .foregroundColor(.white)
                        }
                        NavigationLink {
                            KVKKView()
                        } label: {
                            Text("Kullanıcı sözleşmesini ve KVKK aydınlatma metnini kabul ediyorum.")
                                .font(.footnote)
                                .underline()
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 24)
                Spacer()
                PrimaryButton(
                    title: "Tamamla",
                    action: {},
                    background: Color(red: 143/255, green: 217/255, blue: 83/255),
                    foreground: .white
                )
                .disabled(!canSubmit)
                .frame(height: 48)
                .padding(.horizontal, 24)
                Spacer(minLength: 20)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct CreatePasswordView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CreatePasswordView()
        }
    }
}
