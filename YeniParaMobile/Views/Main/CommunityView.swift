import SwiftUI

struct CommunityView: View {
    @ObservedObject var authVM: AuthViewModel
    
    var body: some View {
        ForumView(authVM: authVM)
    }
}

struct CommunityView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CommunityView(authVM: AuthViewModel())
        }
        .preferredColorScheme(.dark)
    }
}
