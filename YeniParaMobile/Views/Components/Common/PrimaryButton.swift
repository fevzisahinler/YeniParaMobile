import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isEnabled: Bool = true
    var background: Color = AppColors.primary
    var foreground: Color = .black
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foreground))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .foregroundColor(isEnabled ? foreground : .white.opacity(0.6))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isEnabled ? background : Color.white.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isEnabled ? Color.clear : Color.white.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
        .disabled(!isEnabled || isLoading)
    }
}
