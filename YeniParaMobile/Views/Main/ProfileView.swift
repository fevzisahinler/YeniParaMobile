import SwiftUI

struct ProfileView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var showSettings = false
    @State private var showSecurity = false
    @State private var showNotifications = false
    @State private var showHelp = false
    @State private var showAbout = false
    
    var body: some View {
        NavigationStack {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header with Settings Button
                    HStack {
                        Spacer()
                        
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundColor(AppColors.textPrimary)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(AppColors.cardBackground)
                                        .overlay(
                                            Circle()
                                                .stroke(AppColors.cardBorder, lineWidth: 1)
                                        )
                                )
                        }
                    }
                    .padding(.horizontal, AppConstants.screenPadding)
                    .padding(.top, 10)
                    
                    // Profil header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [AppColors.primary, AppColors.secondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            if let profile = authVM.investorProfile {
                                Text(profile.icon ?? "📊")
                                    .font(.system(size: 50))
                            } else {
                                Text(authVM.currentUser?.fullName.prefix(1).uppercased() ?? "U")
                                    .font(.system(size: 42, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)
                            }
                        }
                        
                        VStack(spacing: 8) {
                            Text(authVM.currentUser?.fullName ?? "Kullanıcı")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            if let profile = authVM.investorProfile {
                                HStack(spacing: 8) {
                                    Text(profile.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(AppColors.primary)
                                    
                                    if let nickname = profile.nickname {
                                        Text("•")
                                            .foregroundColor(AppColors.textTertiary)
                                        Text(nickname)
                                            .font(.subheadline)
                                            .foregroundColor(AppColors.textSecondary)
                                            .italic()
                                    }
                                }
                            }
                            
                            Text(authVM.currentUser?.email ?? "user@example.com")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    
                    // Hesap bilgileri kartı
                    AccountInfoCard(authVM: authVM)
                    
                    // Forum İstatistikleri
                    ForumStatsCard()
                    
                    // Takip Edilen Hisseler
                    FollowedStocksCard()
                    
                    // Profil menü seçenekleri
                    VStack(spacing: 16) {
                        Button(action: { showSecurity = true }) {
                            ProfileMenuItem(icon: "shield", title: "Güvenlik")
                        }
                        
                        Button(action: { showNotifications = true }) {
                            ProfileMenuItem(icon: "bell", title: "Bildirimler")
                        }
                        
                        Button(action: { showHelp = true }) {
                            ProfileMenuItem(icon: "questionmark.circle", title: "Yardım & Destek")
                        }
                        
                        Button(action: { showAbout = true }) {
                            ProfileMenuItem(icon: "info.circle", title: "Hakkında")
                        }
                        
                        Button(action: {
                            authVM.logout()
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
        .navigationDestination(isPresented: $showSettings) {
            SettingsView(authVM: authVM)
        }
        .navigationDestination(isPresented: $showSecurity) {
            SecurityView(authVM: authVM)
        }
        .navigationDestination(isPresented: $showNotifications) {
            NotificationsView()
        }
        .navigationDestination(isPresented: $showHelp) {
            HelpSupportView()
        }
        .navigationDestination(isPresented: $showAbout) {
            AboutView()
        }
        }
    }
}

// MARK: - Forum Stats Card
struct ForumStatsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.title3)
                    .foregroundColor(AppColors.primary)
                
                Text("Forum Aktivitesi")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text("Yeni Üye")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(AppColors.primary.opacity(0.15))
                    )
            }
            
            // Stats Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForumStatItem(
                    icon: "doc.text",
                    value: "0",
                    label: "Konu"
                )
                ForumStatItem(
                    icon: "message",
                    value: "0",
                    label: "Mesaj"
                )
                ForumStatItem(
                    icon: "hand.thumbsup",
                    value: "0",
                    label: "Beğeni"
                )
            }
            
            Divider()
                .background(AppColors.cardBorder)
            
            HStack(spacing: 12) {
                Image(systemName: "trophy.fill")
                    .font(.title3)
                    .foregroundColor(Color(red: 255/255, green: 215/255, blue: 0/255))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("İtibar Puanı")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("0 puan")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Text("Forum'a Git")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        .padding(AppConstants.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )
        )
        .padding(.horizontal, AppConstants.screenPadding)
    }
}

// MARK: - Forum Stat Item
struct ForumStatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppColors.primary.opacity(0.8))
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.cardBorder.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

// MARK: - Followed Stocks Card
struct FollowedStocksCard: View {
    @State private var followedStocks = ["AAPL.US"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.title3)
                    .foregroundColor(AppColors.primary)
                
                Text("Takip Ettiğim Hisseler")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text("\(followedStocks.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Circle()
                            .fill(AppColors.primary.opacity(0.15))
                    )
            }
            
            if followedStocks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "star.slash")
                        .font(.title)
                        .foregroundColor(AppColors.textTertiary)
                    
                    Text("Henüz hisse takip etmiyorsunuz")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(followedStocks, id: \.self) { stock in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [AppColors.primary, AppColors.secondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text(String(stock.prefix(2)))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(stock)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                HStack(spacing: 8) {
                                    Label("Haberler", systemImage: "bell.fill")
                                        .font(.caption2)
                                        .foregroundColor(AppColors.primary)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textTertiary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            
            if !followedStocks.isEmpty {
                Button(action: {}) {
                    Text("Tümünü Gör")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppColors.primary.opacity(0.1))
                        )
                }
            }
        }
        .padding(AppConstants.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )
        )
        .padding(.horizontal, AppConstants.screenPadding)
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
