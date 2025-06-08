import SwiftUI

struct ProfileInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authVM: AuthViewModel

    @FocusState private var focusedField: Field?
    private enum Field: Hashable {
        case fullName, username, phone
    }

    private let countryOptions: [(code: String, flag: String)] = [
        ("+90", "🇹🇷"),
        ("+1",  "🇺🇸"),
        ("+44", "🇬🇧"),
        ("+49", "🇩🇪"),
        ("+33", "🇫🇷")
    ]

    @State private var countryCode: String = "+90"
    
    private var isFormValid: Bool {
        !authVM.newUserFullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !authVM.newUserUsername.trimmingCharacters(in: .whitespaces).isEmpty &&
        authVM.newUserPhoneNumber.filter(\.isNumber).count == 11
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
                .padding(.horizontal, 24)
                .padding(.top, 12)

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)

                Text("Sizi Tanıyalım")
                    .font(.largeTitle).bold()
                    .foregroundColor(.white)

                Text("Profilinizi oluşturmak için ihtiyacımız olan bilgiler")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 16) {
                    Text("İsim & Soyisim")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                    InputField(text: $authVM.newUserFullName, placeholder: "__ ________")
                        .textContentType(.name)
                        .autocapitalization(.words)
                        .focused($focusedField, equals: .fullName)

                    Text("Kullanıcı Adı")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                    InputField(text: $authVM.newUserUsername, placeholder: "____.___")
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .focused($focusedField, equals: .username)

                    Text("Telefon Numarası")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))

                    HStack(spacing: 8) {
                        Menu {
                            ForEach(countryOptions, id: \.code) { option in
                                Button {
                                    countryCode = option.code
                                } label: {
                                    Text("\(option.flag) \(option.code)")
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(countryOptions.first { $0.code == countryCode }?.flag ?? "")
                                Text(countryCode)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                        }

                        InputField(text: $authVM.newUserPhoneNumber, placeholder: "(___) ___ __ __")
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .focused($focusedField, equals: .phone)
                            .onChange(of: authVM.newUserPhoneNumber) { newValue in
                                var digits = newValue.filter(\.isNumber)
                                if digits.count > 11 {
                                    digits = String(digits.prefix(11))
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
                }
                .padding(.horizontal, 24)

                NavigationLink(
                    destination: CreatePasswordView(authVM: authVM),
                    label: {
                        PrimaryButton(
                            title: "İleri",
                            action: { },
                            background: Color(red: 143/255, green: 217/255, blue: 83/255),
                            foreground: .white
                        )
                        .frame(height: 48)
                        .padding(.horizontal, 24)
                        .disabled(!isFormValid)
                    }
                )

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct ProfileInfoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileInfoView(authVM: AuthViewModel())
        }
    }
}
