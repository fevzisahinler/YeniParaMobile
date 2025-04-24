import SwiftUI

struct ContentView: View {
    @ObservedObject var authVM: AuthViewModel
    var body: some View {
        WelcomeView(authVM: authVM)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(authVM: AuthViewModel())
    }
}
