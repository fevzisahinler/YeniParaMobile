

import SwiftUI

struct EmailVerificationView: View {
    @Environment(\.dismiss) private var dismiss
    let email: String

    @State private var code: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusIndex: Int?

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

                VStack(spacing: 4) {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Text("adresine gönderilen doğrulama kodunu girin")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                }

                HStack(spacing: 12) {
                    ForEach(0..<6) { i in
                        TextField("", text: $code[i])
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.title2)
                            .frame(width: 45, height: 55)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                            .focused($focusIndex, equals: i)
                            .onChange(of: code[i]) { new in
                                if let ch = new.first, ch.isNumber {
                                    code[i] = String(ch)
                                    if i < 5 { focusIndex = i + 1 }
                                    else      { focusIndex = nil }
                                } else {
                                    code[i] = ""
                                }
                            }
                    }
                }

                PrimaryButton(
                    title: "İleri",
                    action: {
                    },
                    background: Color(red: 143/255, green: 217/255, blue: 83/255),
                    foreground: .white
                )
                .disabled(!isComplete)
                .frame(height: 48)
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear { focusIndex = 0 }
    }
}

struct EmailVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            EmailVerificationView(email: "ornek@domain.com")
        }
    }
}
