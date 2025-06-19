import SwiftUI

struct CustomTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    @State private var isPasswordVisible: Bool = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                if isSecure && !isPasswordVisible {
                    SecureField(placeholder, text: $text)
                        .textContentType(.password)
                        .foregroundColor(.white)
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .autocapitalization(keyboardType == .emailAddress ? .none : .sentences)
                        .foregroundColor(.white)
                        .focused($isFocused)
                }
                
                if isSecure {
                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isFocused ? AppColors.primary : Color.white.opacity(0.2),
                                lineWidth: 1
                            )
                    )
            )
        }
    }
}
