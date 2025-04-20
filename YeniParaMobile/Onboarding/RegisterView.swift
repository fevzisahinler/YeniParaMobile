import SwiftUI

struct RegisterView: View {
    @ObservedObject var authVM: AuthViewModel

    var body: some View {
        VStack(spacing: 32) {
            LogoView()
                .padding(.top, 60)

            Text("Kayıt Ekranı")
                .font(.largeTitle)
                .bold()
            
            Spacer()

            Button("Geri Dön") {
                authVM.showRegister = false
            }
            .padding(.bottom, 24)
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView(authVM: AuthViewModel())
    }
}
