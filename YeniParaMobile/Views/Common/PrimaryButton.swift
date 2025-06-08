import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var background: Color = .green
    var foreground: Color = .white

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(foreground)
                .frame(maxWidth: CGFloat.infinity)
                .padding()
                .background(background)
                .cornerRadius(8)
        }
    }
}

struct PrimaryButton_Previews: PreviewProvider {
    static var previews: some View {
        PrimaryButton(title: "Test", action: {})
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
