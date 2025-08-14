import SwiftUI

struct PublicProfileView: View {
    let username: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PublicProfileViewModel()
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Navigation Bar
                customNavigationBar
                
                if viewModel.isLoading {
                    LoadingView(message: "Profil yükleniyor...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error) {
                        Task {
                            await viewModel.loadProfile(username: username)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let profile = viewModel.profile {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Profile Header
                            profileHeaderSection(profile)
                            
                            // Investor Profile
                            investorProfileSection(profile.investorProfile)
                            
                            // Forum Stats
                            forumStatsSection(profile.forumStats)
                            
                            // Recent Threads
                            if !profile.recentThreads.isEmpty {
                                recentThreadsSection(profile.recentThreads)
                            }
                            
                            // Badges
                            if !profile.badges.isEmpty {
                                badgesSection(profile.badges)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.loadProfile(username: username)
            }
        }
    }
    
    // MARK: - Custom Navigation Bar
    private var customNavigationBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Geri")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(AppColors.textPrimary)
            }
            
            Spacer()
            
            Text("Profil")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AppColors.background)
    }
    
    // MARK: - Profile Header Section
    private func profileHeaderSection(_ profile: PublicProfileData) -> some View {
        VStack(spacing: 20) {
            // Avatar and basic info
            VStack(spacing: 16) {
                // Avatar
                AuthorizedAsyncImage(
                    photoPath: profile.profilePhotoPath,
                    size: 100,
                    fallbackText: profile.username
                )
                
                VStack(spacing: 8) {
                    Text("@\(profile.username)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Üye: \(TimeFormatter.formatMemberSince(profile.memberSince))")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Investor Profile Section
    private func investorProfileSection(_ profile: PublicInvestorProfile) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Yatırımcı Profili")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Profile Type Card
                HStack(spacing: 16) {
                    Text(profile.icon)
                        .font(.system(size: 40))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(profile.nickname)
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.primary.opacity(0.2), lineWidth: 1)
                        )
                )
                
                // Profile Description
                Text(profile.description)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(4)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.cardBackground)
                    )
                
                // Allocation Chart
                allocationChartView(profile)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Forum Stats Section
    private func forumStatsSection(_ stats: PublicForumStats) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Forum İstatistikleri")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                PublicStatCard(
                    title: "Konu Açtı",
                    value: "\(stats.threadsCreated)",
                    icon: "bubble.left.and.bubble.right",
                    color: AppColors.primary
                )
                
                PublicStatCard(
                    title: "En İyi Cevap",
                    value: "\(stats.bestAnswers)",
                    icon: "star.fill",
                    color: Color.orange
                )
                
                PublicStatCard(
                    title: "Beğeni Aldı",
                    value: "\(stats.likesReceived)",
                    icon: "heart.fill",
                    color: AppColors.error
                )
                
                PublicStatCard(
                    title: "İtibar Puanı",
                    value: "\(stats.reputationScore)",
                    icon: "trophy.fill",
                    color: Color.yellow
                )
            }
            
            // Forum Title Badge
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(Color.yellow)
                Text(stats.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.yellow.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Recent Threads Section
    private func recentThreadsSection(_ threads: [PublicRecentThread]) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Son Konular")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            
            LazyVStack(spacing: 12) {
                ForEach(threads.prefix(5)) { thread in
                    PublicThreadRowView(thread: thread)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Badges Section
    private func badgesSection(_ badges: [UserBadge]) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Rozetler")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(badges) { badge in
                    PublicBadgeView(badge: badge)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Allocation Chart View
    private func allocationChartView(_ profile: PublicInvestorProfile) -> some View {
        VStack(spacing: 12) {
            Text("Portföy Dağılımı")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: 16) {
                AllocationBarView(
                    title: "Hisse",
                    percentage: profile.stockAllocationPercentage,
                    color: AppColors.primary
                )
                
                AllocationBarView(
                    title: "Tahvil",
                    percentage: profile.bondAllocationPercentage,
                    color: Color.orange
                )
                
                AllocationBarView(
                    title: "Nakit",
                    percentage: profile.cashAllocationPercentage,
                    color: AppColors.textSecondary
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackground)
        )
    }
    
}

// MARK: - Supporting Views

struct PublicStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct PublicThreadRowView: View {
    let thread: PublicRecentThread
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(thread.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(2)
            
            Text(thread.content)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(3)
            
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "eye")
                        .font(.caption)
                    Text("\(thread.viewCount)")
                        .font(.caption)
                }
                .foregroundColor(AppColors.textTertiary)
                
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                        .font(.caption)
                    Text("\(thread.replyCount)")
                        .font(.caption)
                }
                .foregroundColor(AppColors.textTertiary)
                
                HStack(spacing: 4) {
                    Image(systemName: "heart")
                        .font(.caption)
                    Text("\(thread.likeCount)")
                        .font(.caption)
                }
                .foregroundColor(AppColors.textTertiary)
                
                Spacer()
                
                Text(TimeFormatter.formatTimeAgo(thread.createdAt))
                    .font(.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackground)
        )
    }
}

struct PublicBadgeView: View {
    let badge: UserBadge
    
    var body: some View {
        VStack(spacing: 6) {
            Text(badge.icon)
                .font(.system(size: 24))
            
            Text(badge.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.primary.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct AllocationBarView: View {
    let title: String
    let percentage: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.2))
                    .frame(width: 6, height: 60)
                    .overlay(
                        VStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 6)
                                .fill(color)
                                .frame(height: CGFloat(percentage) * 0.6)
                        }
                    )
            }
            
            Text("\(percentage)%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - ViewModel
@MainActor
class PublicProfileViewModel: ObservableObject {
    @Published var profile: PublicProfileData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadProfile(username: String) async {
        isLoading = true
        errorMessage = nil
        
        // Debug logging removed for production
        
        guard !username.isEmpty else {
            errorMessage = "Kullanıcı adı boş"
            isLoading = false
            return
        }
        
        do {
            let response = try await APIService.shared.getPublicProfile(username: username)
            // Debug logging removed for production
            if response.success {
                if let profileData = response.data {
                    // Debug logging removed for production
                    profile = profileData
                } else {
                    // Debug logging removed for production
                    errorMessage = "Profil verisi alınamadı"
                }
            } else {
                errorMessage = "Profil yüklenemedi"
            }
        } catch {
            // Debug logging removed for production
            if let decodingError = error as? DecodingError {
                // Debug logging removed for production
            }
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Preview
struct PublicProfileView_Previews: PreviewProvider {
    static var previews: some View {
        PublicProfileView(username: "fevzisahinler")
            .preferredColorScheme(.dark)
    }
}