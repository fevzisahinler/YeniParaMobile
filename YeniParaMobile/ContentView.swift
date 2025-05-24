// ContentView.swift - Tab bar sorununu çözen versiyon
import SwiftUI

struct ContentView: View {
    @ObservedObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if authVM.isLoggedIn {
                // Tab bar tüm sayfalarda görünecek - NavigationStack kaldırıldı
                TabBarView(authVM: authVM)
            } else {
                // Sadece onboarding'de Navigation Stack kullan
                NavigationStack {
                    WelcomeView(authVM: authVM)
                        .navigationBarHidden(true)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            #if DEBUG
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                authVM.isLoggedIn = true
            }
            #endif
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(authVM: AuthViewModel())
            .preferredColorScheme(.dark)
    }
}
