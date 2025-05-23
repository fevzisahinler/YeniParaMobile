import SwiftUI

struct TabBarView: View {
    @ObservedObject var authVM: AuthViewModel

    var body: some View {
        TabView {
            HomeView(authVM: authVM)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            Text("Diğer")
                .tabItem {
                    Image(systemName: "ellipsis.circle")
                    Text("Diğer")
                }
        }
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView(authVM: AuthViewModel())
    }
}