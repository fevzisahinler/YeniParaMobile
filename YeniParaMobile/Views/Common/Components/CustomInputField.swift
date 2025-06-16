import SwiftUI

// MARK: - Basic Custom Input Field
struct CustomInputField: View {
    @Binding var text: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    
    @State private var isFocused = false
    @FocusState private var focusState: Bool
    
    init(text: Binding<String>, placeholder: String, keyboardType: UIKeyboardType = .default) {
        self._text = text
        self.placeholder = placeholder
        self.keyboardType = keyboardType
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .leading) {
                // Placeholder with underscores
                if text.isEmpty && !isFocused {
                    HStack(spacing: 0) {
                        ForEach(Array(placeholder.enumerated()), id: \.offset) { index, char in
                            if char == " " {
                                Text(" ")
                                    .font(.system(size: 16))
                            } else {
                                Text(String(char))
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.3))
                                    .underline(true, color: .white.opacity(0.3))
                            }
                        }
                    }
                }
                
                // Actual TextField
                TextField("", text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .keyboardType(keyboardType)
                    .focused($focusState)
                    .onChange(of: focusState) { newValue in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isFocused = newValue
                        }
                    }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFocused ? Color(red: 143/255, green: 217/255, blue: 83/255) : Color.white.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Name Input Field
struct NameInputField: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                TextField("", text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .textContentType(.name)
                    .autocapitalization(.words)
                    .focused($isFocused)
                    .background(Color.clear)
                
                Spacer()
            }
            .padding(.vertical, 12)
            .overlay(
                // Custom placeholder with underscores
                HStack(spacing: 0) {
                    if text.isEmpty {
                        // İsim için altı çizgiler
                        ForEach(0..<6, id: \.self) { _ in
                            Text("_")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        Text(" ")
                            .font(.system(size: 16))
                        // Soyisim için altı çizgiler
                        ForEach(0..<8, id: \.self) { _ in
                            Text("_")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        Spacer()
                    }
                }
                .allowsHitTesting(false)
                .padding(.vertical, 12),
                alignment: .leading
            )
            
            // Alt çizgi
            Rectangle()
                .fill(isFocused ? Color(red: 143/255, green: 217/255, blue: 83/255) : Color.white.opacity(0.3))
                .frame(height: 1)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Username Input Field
struct UsernameInputField: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                TextField("", text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .focused($isFocused)
                    .background(Color.clear)
                
                Spacer()
            }
            .padding(.vertical, 12)
            .overlay(
                // Custom placeholder
                HStack(spacing: 0) {
                    if text.isEmpty {
                        ForEach(0..<4, id: \.self) { _ in
                            Text("_")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        Text(".")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.4))
                        ForEach(0..<3, id: \.self) { _ in
                            Text("_")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        Spacer()
                    }
                }
                .allowsHitTesting(false)
                .padding(.vertical, 12),
                alignment: .leading
            )
            
            Rectangle()
                .fill(isFocused ? Color(red: 143/255, green: 217/255, blue: 83/255) : Color.white.opacity(0.3))
                .frame(height: 1)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Phone Input Field
struct PhoneInputField: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                TextField("", text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .keyboardType(.numberPad)
                    .textContentType(.telephoneNumber)
                    .focused($isFocused)
                    .background(Color.clear)
                
                Spacer()
            }
            .padding(.vertical, 12)
            .overlay(
                // Phone number placeholder
                HStack(spacing: 0) {
                    if text.isEmpty {
                        Text("(")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.4))
                        ForEach(0..<3, id: \.self) { _ in
                            Text("_")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        Text(") ")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.4))
                        ForEach(0..<3, id: \.self) { _ in
                            Text("_")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        Text(" ")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.4))
                        ForEach(0..<2, id: \.self) { _ in
                            Text("_")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        Text(" ")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.4))
                        ForEach(0..<2, id: \.self) { _ in
                            Text("_")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        Spacer()
                    }
                }
                .allowsHitTesting(false)
                .padding(.vertical, 12),
                alignment: .leading
            )
            
            Rectangle()
                .fill(isFocused ? Color(red: 143/255, green: 217/255, blue: 83/255) : Color.white.opacity(0.3))
                .frame(height: 1)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}
