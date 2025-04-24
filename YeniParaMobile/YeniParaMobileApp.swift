import SwiftUI

@main
struct YeniParaMobileApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
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
