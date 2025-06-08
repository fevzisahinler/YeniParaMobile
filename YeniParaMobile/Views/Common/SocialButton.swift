import SwiftUI

struct SocialButton: View {
    let imageName: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text(title)
                    .font(.body).bold()
            }
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
        }
    }
}

struct SocialButton_Previews: PreviewProvider {
    static var previews: some View {
        SocialButton(imageName: "google-logo",
                     title: "Google ile devam et",
                     action: {})
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
