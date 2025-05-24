import SwiftUI

struct ProfileView: View {
    @ObservedObject var authVM: AuthViewModel
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Profil header
                    VStack(spacing: 16) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.secondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text("U")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.textPrimary)
                            )
                        
                        VStack(spacing: 4) {
                            Text("Kullanıcı")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("user@example.com")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Hesap bilgileri kartı
                    AccountInfoCard()
                    
                    // Profil menü seçenekleri
                    VStack(spacing: 16) {
                        ProfileMenuItem(icon: "gear", title: "Ayarlar")
                        ProfileMenuItem(icon: "shield", title: "Güvenlik")
                        ProfileMenuItem(icon: "bell", title: "Bildirimler")
                        ProfileMenuItem(icon: "questionmark.circle", title: "Yardım & Destek")
                        ProfileMenuItem(icon: "info.circle", title: "Hakkında")
                        
                        Button(action: {
                            authVM.isLoggedIn = false
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.title3)
                                    .foregroundColor(AppColors.error)
                                
                                Text("Çıkış Yap")
                                    .font(.headline)
                                    .foregroundColor(AppColors.error)
                                
                                Spacer()
                            }
                            .padding(.horizontal, AppConstants.screenPadding)
                            .padding(.vertical, 16)
                            .background(AppColors.cardBackground)
                            .cornerRadius(AppConstants.cornerRadius)
                        }
                    }
                    .padding(.horizontal, AppConstants.screenPadding)
                    
                    Spacer(minLength: 100)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileView(authVM: AuthViewModel())
        }
        .preferredColorScheme(.dark)
    }
}
