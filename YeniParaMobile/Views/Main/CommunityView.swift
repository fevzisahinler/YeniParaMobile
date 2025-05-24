import SwiftUI

struct CommunityView: View {
    @ObservedObject var authVM: AuthViewModel
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Topluluk")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Yatırımcılarla etkileşim")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "plus.circle")
                                .font(.title3)
                                .foregroundColor(AppColors.textPrimary)
                                .frame(width: 40, height: 40)
                                .background(AppColors.cardBackground)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, AppConstants.screenPadding)
                    .padding(.top, 8)
                    
                    // Popüler konular
                    PopularTopicsSection()
                    
                    // Yakında gelecek özellikler
                    ComingSoonSection()
                }
                .padding(.vertical, 20)
            }
        }
        .navigationBarHidden(true)
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
