import SwiftUI

struct InputField: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white.opacity(0.1))
            .foregroundColor(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .frame(maxWidth: .infinity)
    }
}

struct InputField_Previews: PreviewProvider {
    @State static var val = ""
    static var previews: some View {
        InputField(text: $val, placeholder: "E‑Posta")
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
