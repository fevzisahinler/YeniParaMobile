import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var background: Color
    var foreground: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(foreground)
            .padding()
            .frame(maxWidth: .infinity)
            .background(background)
            .cornerRadius(8)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
