import SwiftUI

@main
struct YeniParaMobileApp: App {
    @StateObject private var authVM = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WelcomeView(authVM: authVM)
                    .navigationBarHidden(true)
            }
        }
    }
}
