import SwiftUI

struct PhoneNumberEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var phone: String = ""
    @FocusState private var focusedField: Bool
    @State private var acceptedTerms: Bool = false

    private var isValidPhone: Bool {
        phone.filter(\.isNumber).count == 10
    }

    var onSubmit: (String) -> Void

    var body: some View {
        ZStack {
            Color(red: 28/255, green: 29/255, blue: 36/255)
                .ignoresSafeArea()

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

                Text("Telefon Numaranızı Girin")
                    .font(.largeTitle).bold()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text("Güvenlik ve doğrulama için telefon numaranızı giriniz.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Telefon Numarası")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 24)

                    TextField("(___) ___ __ __", text: $phone)
                        .keyboardType(.numberPad)
                        .focused($focusedField)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.horizontal, 24)
                        .onChange(of: phone) { newValue in
                            var digits = newValue.filter(\.isNumber)
                            if digits.count > 10 {
                                digits = String(digits.prefix(10))
                            }
                            var formatted = ""
                            for (i, ch) in digits.enumerated() {
                                if i == 0 { formatted += "(" }
                                if i == 3 { formatted += ") " }
                                if i == 6 { formatted += " " }
                                if i == 8 { formatted += " " }
                                formatted.append(ch)
                            }
                            phone = formatted
                        }
                    
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
        
                Button(action: { onSubmit(phone) }) {
                    Text("İleri")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(isValidPhone ? Color(red: 143/255, green: 217/255, blue: 83/255) : Color.gray)
                        .cornerRadius(8)
                }
                .disabled(!isValidPhone)
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear { focusedField = true }
    }
}

struct PhoneNumberEntryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PhoneNumberEntryView { phone in
                print("Girilen telefon: \(phone)")
            }
        }
    }
}
