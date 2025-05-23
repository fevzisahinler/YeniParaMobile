
import SwiftUI

struct ContentView: View {
    @ObservedObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if authVM.isLoggedIn {
                TabBarView(authVM: authVM)
            } else {
                WelcomeView(authVM: authVM)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(authVM: AuthViewModel())
    }
}
