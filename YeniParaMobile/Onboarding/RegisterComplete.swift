import SwiftUI

struct RegisterCompleteView: View {
    var onStart: () -> Void
    var onLater: () -> Void

    var body: some View {
        ZStack {
            Color(red: 28/255, green: 29/255, blue: 36/255)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer().frame(height: 40)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Color(red: 143/255, green: 217/255, blue: 83/255))

                Text("Kayıt Başarıyla Tamamlandı")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Sizin için en uygun yatırım profilini belirlemek üzere birkaç sorumuz var.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Image("registercomplete")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 200, maxHeight: 200)

                PrimaryButton(
                    title: "Başla",
                    action: onStart,
                    background: Color(red: 143/255, green: 217/255, blue: 83/255),
                    foreground: .white
                )
                .frame(height: 48)
                .padding(.horizontal, 24)

                Text("Yaklaşık 1 dakikanızı alacak")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.7))

                Button(action: onLater) {
                    Text("Daha sonra tamamla")
                        .font(.footnote)
                        .underline()
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

struct RegisterCompleteView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RegisterCompleteView(
                onStart: {},
                onLater: {}
            )
        }
    }
}
