import SwiftUI

struct ProfileView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var showSettings = false
    @State private var showSecurity = false
    @State private var showNotifications = false
    @State private var showHelp = false
    @State private var showAbout = false
    @State private var showEditProfile = false
    @State private var profileData: UserProfileData?
    @State private var followedStocks: [FollowedStock] = []
    @State private var isLoading = true
    @State private var showInvestorProfileDetail = false
    
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
                        // Profile Photo with authorization
                        ProfileImageView(
                            photoPath: authVM.userProfile?.user.profilePhotoPath,
                            size: 100,
                            fallbackIcon: authVM.investorProfile?.icon,
                            fallbackText: String(authVM.userProfile?.user.fullName.prefix(1).uppercased() ?? "U")
                        )
                        
                        VStack(spacing: 8) {
                            Text(authVM.userProfile?.user.fullName ?? authVM.currentUser?.fullName ?? "Kullanıcı")
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
                            
                            Text(authVM.userProfile?.user.email ?? authVM.currentUser?.email ?? "")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        // Edit Profile Button - Daha belirgin
                        Button(action: { showEditProfile = true }) {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.pencil")
                                    .font(.system(size: 16))
                                Text("Profili Düzenle")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(AppColors.primary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(AppColors.primary, lineWidth: 1.5)
                            )
                        }
                        .padding(.top, 8)
                    }
                    
                    // Hesap bilgileri kartı
                    ProfileAccountInfoCard(authVM: authVM)
                    
                    // Investor Profile Card
                    if let profile = profileData?.investorProfile {
                        InvestorProfileCard(
                            profile: profile,
                            onShowDetail: { showInvestorProfileDetail = true }
                        )
                    }
                    
                    // Forum İstatistikleri
                    if let stats = profileData?.forumStats {
                        ForumStatsCard(stats: stats)
                    }
                    
                    // Takip Edilen Hisseler
                    FollowedStocksCard(
                        followedStocks: followedStocks,
                        investorProfile: authVM.investorProfile
                    )
                    
                    // Profil menü seçenekleri
                    VStack(spacing: 16) {
                        Button(action: { showSecurity = true }) {
                            ProfileMenuItemView(icon: "shield", title: "Güvenlik")
                        }
                        
                        Button(action: { showNotifications = true }) {
                            ProfileMenuItemView(icon: "bell", title: "Bildirimler")
                        }
                        
                        Button(action: { showHelp = true }) {
                            ProfileMenuItemView(icon: "questionmark.circle", title: "Yardım & Destek")
                        }
                        
                        Button(action: { showAbout = true }) {
                            ProfileMenuItemView(icon: "info.circle", title: "Hakkında")
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
        .task {
            await loadProfileData()
            await loadFollowedStocks()
        }
        .onAppear {
            // Ensure profile is loaded on first appear
            Task {
                await authVM.getUserProfile()
            }
        }
        .navigationDestination(isPresented: $showSettings) {
            SettingsView(authVM: authVM)
        }
        .navigationDestination(isPresented: $showEditProfile) {
            EditProfileView(authVM: authVM)
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
        .sheet(isPresented: $showInvestorProfileDetail) {
            if let profile = profileData?.investorProfile {
                InvestorProfileDetailSheet(profile: profile)
            }
        }
        }
    }
    
    // MARK: - Helper Functions
    func loadProfileData() async {
        // AuthViewModel'den getUserProfile çağır
        await authVM.getUserProfile()
        
        do {
            let response = try await APIService.shared.getUserProfile()
            await MainActor.run {
                self.profileData = response.data
                self.isLoading = false
            }
        } catch {
            print("Error loading profile: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    func loadFollowedStocks() async {
        do {
            let response = try await APIService.shared.getFollowedStocks()
            await MainActor.run {
                self.followedStocks = response.data.stocks
            }
        } catch {
            print("Error loading followed stocks: \(error)")
        }
    }
}

// MARK: - Forum Stats Card
struct ForumStatsCard: View {
    let stats: ForumStats
    
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
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                        Text("\(stats.reputationScore)")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(Color.yellow)
                    
                    Text(stats.title)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.primary)
                }
            }
            
            // Stats Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForumStatItem(
                    icon: "bubble.left",
                    value: "\(stats.threadsCreated)",
                    label: "Konu"
                )
                
                ForumStatItem(
                    icon: "hand.thumbsup",
                    value: "\(stats.likesReceived)",
                    label: "Beğeni"
                )
                
                ForumStatItem(
                    icon: "star",
                    value: "\(stats.bestAnswers)",
                    label: "En İyi Cevap"
                )
            }
        }
        .padding(20)
        .background(AppColors.cardBackground)
        .cornerRadius(AppConstants.cornerRadius)
        .padding(.horizontal, AppConstants.screenPadding)
    }
}

struct ForumStatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppColors.primary.opacity(0.7))
            
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
                .fill(AppColors.background)
        )
    }
}

// MARK: - Profile Account Info Card
struct ProfileAccountInfoCard: View {
    @ObservedObject var authVM: AuthViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.text.rectangle.fill")
                    .font(.title3)
                    .foregroundColor(AppColors.primary)
                
                Text("Hesap Bilgileri")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                AccountInfoRow(label: "Kullanıcı Adı", value: "@\(authVM.username)")
                AccountInfoRow(label: "Telefon", value: authVM.userProfile?.user.phoneNumber ?? "Belirtilmemiş")
                AccountInfoRow(label: "Kayıt Tarihi", value: formatDate(authVM.currentUser?.createdAt ?? ""))
            }
        }
        .padding(20)
        .background(AppColors.cardBackground)
        .cornerRadius(AppConstants.cornerRadius)
        .padding(.horizontal, AppConstants.screenPadding)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return "Bilinmiyor" }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.locale = Locale(identifier: "tr_TR")
        return displayFormatter.string(from: date)
    }
}

struct AccountInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

// MARK: - Followed Stocks Card
struct FollowedStocksCard: View {
    let followedStocks: [FollowedStock]
    let investorProfile: InvestorProfile?
    @State private var showAllStocks = false
    @State private var stockQuotes: [String: StockQuote] = [:]
    @State private var stockDetails: [String: SP100Symbol] = [:]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.title3)
                    .foregroundColor(AppColors.error)
                
                Text("Takip Ettiğim Hisseler")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                if !followedStocks.isEmpty {
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
            }
            
            if followedStocks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "heart.slash")
                        .font(.title)
                        .foregroundColor(AppColors.textTertiary)
                    
                    Text("Henüz hisse takip etmiyorsunuz")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Investor Profile Info
                if let profile = investorProfile {
                    HStack(spacing: 12) {
                        if let icon = profile.icon {
                            Text(icon)
                                .font(.title2)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(profile.name)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.primary)
                            
                            if let nickname = profile.nickname {
                                Text(nickname)
                                    .font(.caption2)
                                    .foregroundColor(AppColors.textSecondary)
                            } else {
                                Text("Risk: \(profile.riskTolerance.lowercased().capitalized)")
                                    .font(.caption2)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "chart.pie.fill")
                                .font(.caption)
                            Text("\(profile.stockAllocationPercentage)% Hisse")
                                .font(.caption2)
                        }
                        .foregroundColor(AppColors.textTertiary)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppColors.primary.opacity(0.05))
                    )
                }
                
                VStack(spacing: 12) {
                    ForEach(followedStocks.prefix(5)) { stock in
                        FollowedStockRow(
                            stock: stock,
                            quote: stockQuotes[stock.symbolCode],
                            details: stockDetails[stock.symbolCode]
                        )
                    }
                    
                    if followedStocks.count > 5 {
                        Button(action: { showAllStocks = true }) {
                            HStack {
                                Text("Tümünü Görüntüle")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                            .foregroundColor(AppColors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.primary.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(AppColors.cardBackground)
        .cornerRadius(AppConstants.cornerRadius)
        .padding(.horizontal, AppConstants.screenPadding)
        .onAppear {
            loadStockQuotes()
        }
        .sheet(isPresented: $showAllStocks) {
            AllFollowedStocksSheet(
                followedStocks: followedStocks,
                investorProfile: investorProfile
            )
        }
    }
    
    private func loadStockQuotes() {
        Task {
            // Load SP100 symbols first to get details
            do {
                let symbolsResponse = try await APIService.shared.getSP100Symbols()
                if symbolsResponse.success {
                    await MainActor.run {
                        for symbol in symbolsResponse.data.symbols {
                            self.stockDetails[symbol.code] = symbol
                        }
                    }
                }
            } catch {
                print("Error loading symbols: \(error)")
            }
            
            // Then load quotes
            for stock in followedStocks.prefix(5) {
                do {
                    let response = try await APIService.shared.getStockQuote(symbol: stock.symbolCode)
                    if response.success {
                        await MainActor.run {
                            stockQuotes[stock.symbolCode] = response.data
                        }
                    }
                } catch {
                    print("Error loading quote for \(stock.symbolCode): \(error)")
                }
            }
        }
    }
}

// MARK: - Followed Stock Row
struct FollowedStockRow: View {
    let stock: FollowedStock
    let quote: StockQuote?
    let details: SP100Symbol?
    
    var body: some View {
        HStack(spacing: 16) {
            // Logo
            if let details = details {
                AsyncImage(url: URL(string: "http://localhost:4000/api/v1/logos/\(stock.symbolCode).jpeg")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppColors.primary.opacity(0.3),
                                    AppColors.secondary.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Text(String(stock.symbolCode.prefix(2)))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.primary.opacity(0.3),
                                AppColors.secondary.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(String(stock.symbolCode.prefix(2)))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.symbolCode)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                if let details = details {
                    Text(details.name)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                } else {
                    HStack(spacing: 8) {
                        if stock.notifyOnNews {
                            Label("Haber", systemImage: "newspaper.fill")
                                .font(.caption2)
                                .foregroundColor(AppColors.primary)
                        }
                        if stock.notifyOnComment {
                            Label("Yorum", systemImage: "bubble.left.fill")
                                .font(.caption2)
                                .foregroundColor(AppColors.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Price change
            if let quote = quote {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(quote.formattedPrice)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: quote.isPositive ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10))
                        Text(quote.formattedChangePercent)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(quote.changeColor)
                }
            } else {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - All Followed Stocks Sheet
struct AllFollowedStocksSheet: View {
    let followedStocks: [FollowedStock]
    let investorProfile: InvestorProfile?
    @Environment(\.dismiss) private var dismiss
    @State private var stockQuotes: [String: StockQuote] = [:]
    @State private var stockDetails: [String: SP100Symbol] = [:]
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(followedStocks) { stock in
                            Button(action: {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    navigationManager.navigateToStock(stock.symbolCode)
                                }
                            }) {
                                FollowedStockRow(
                                    stock: stock,
                                    quote: stockQuotes[stock.symbolCode],
                                    details: stockDetails[stock.symbolCode]
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Takip Edilen Hisseler (\(followedStocks.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
        .onAppear {
            loadStockQuotes()
        }
    }
    
    private func loadStockQuotes() {
        Task {
            // Load SP100 symbols first to get details
            do {
                let symbolsResponse = try await APIService.shared.getSP100Symbols()
                if symbolsResponse.success {
                    await MainActor.run {
                        for symbol in symbolsResponse.data.symbols {
                            self.stockDetails[symbol.code] = symbol
                        }
                    }
                }
            } catch {
                print("Error loading symbols: \(error)")
            }
            
            // Then load quotes
            for stock in followedStocks {
                do {
                    let response = try await APIService.shared.getStockQuote(symbol: stock.symbolCode)
                    if response.success {
                        await MainActor.run {
                            stockQuotes[stock.symbolCode] = response.data
                        }
                    }
                } catch {
                    print("Error loading quote for \(stock.symbolCode): \(error)")
                }
            }
        }
    }
}

// MARK: - Profile Menu Item View
struct ProfileMenuItemView: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 30, alignment: .center)
            
            Text(title)
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(.horizontal, AppConstants.screenPadding)
        .padding(.vertical, 16)
        .background(AppColors.cardBackground)
        .cornerRadius(AppConstants.cornerRadius)
    }
}

// MARK: - Investor Profile Card
struct InvestorProfileCard: View {
    let profile: InvestorProfile
    let onShowDetail: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                if let icon = profile.icon {
                    Text(icon)
                        .font(.title2)
                }
                
                Text("Yatırımcı Profili")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                // Profile badge
                Text(profile.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.background)  // Dark background color for better contrast
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(AppColors.primary)
                    )
            }
            
            // Profile description
            VStack(alignment: .leading, spacing: 12) {
                if let nickname = profile.nickname {
                    Text("\"\(nickname)\"")
                        .font(.subheadline)
                        .italic()
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Text(profile.description)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)
                
                // Risk and allocation
                HStack(spacing: 20) {
                    HStack(spacing: 6) {
                        Image(systemName: "gauge")
                            .font(.caption)
                        Text("Risk: \(profile.riskTolerance.lowercased().capitalized)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(getRiskColor(profile.riskTolerance))
                    
                    HStack(spacing: 6) {
                        Image(systemName: "chart.pie")
                            .font(.caption)
                        Text("\(profile.stockAllocationPercentage)% Hisse")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(AppColors.primary)
                }
                
                Button(action: onShowDetail) {
                    HStack {
                        Text("Detayları Görüntüle")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundColor(AppColors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.primary.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
        .padding(20)
        .background(AppColors.cardBackground)
        .cornerRadius(AppConstants.cornerRadius)
        .padding(.horizontal, AppConstants.screenPadding)
    }
    
    private func getRiskColor(_ risk: String) -> Color {
        switch risk.uppercased() {
        case "LOW":
            return .green
        case "MEDIUM":
            return .orange
        case "HIGH":
            return .red
        default:
            return AppColors.textSecondary
        }
    }
}

// MARK: - Investor Profile Detail Sheet
struct InvestorProfileDetailSheet: View {
    let profile: InvestorProfile
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            if let icon = profile.icon {
                                Text(icon)
                                    .font(.system(size: 60))
                            }
                            
                            Text(profile.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            if let nickname = profile.nickname {
                                Text("\"\(nickname)\"")
                                    .font(.headline)
                                    .italic()
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Description
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Açıklama", icon: "text.quote")
                            Text(profile.description)
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(AppColors.cardBackground)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        
                        // Goals
                        if let goals = profile.goals {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Hedefler", icon: "target")
                                Text(goals)
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(AppColors.cardBackground)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Advantages & Disadvantages
                        HStack(spacing: 12) {
                            if let advantages = profile.advantages {
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Avantajlar", systemImage: "plus.circle.fill")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                    
                                    Text(advantages)
                                        .font(.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                            }
                            
                            if let disadvantages = profile.disadvantages {
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Dezavantajlar", systemImage: "minus.circle.fill")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.red)
                                    
                                    Text(disadvantages)
                                        .font(.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Portfolio Allocation
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Portföy Dağılımı", icon: "chart.pie")
                            
                            VStack(spacing: 12) {
                                PortfolioAllocationRow(
                                    title: "Hisse Senedi",
                                    percentage: profile.stockAllocationPercentage,
                                    color: AppColors.primary,
                                    icon: "chart.line.uptrend.xyaxis"
                                )
                                PortfolioAllocationRow(
                                    title: "Tahvil",
                                    percentage: profile.bondAllocationPercentage,
                                    color: Color.orange,
                                    icon: "doc.text"
                                )
                                PortfolioAllocationRow(
                                    title: "Nakit",
                                    percentage: profile.cashAllocationPercentage,
                                    color: Color.green,
                                    icon: "banknote"
                                )
                            }
                            .padding()
                            .background(AppColors.cardBackground)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        
                        // Investment Details
                        VStack(spacing: 16) {
                            DetailRow(
                                label: "Risk Toleransı",
                                value: profile.riskTolerance.lowercased().capitalized,
                                color: getRiskColor(profile.riskTolerance)
                            )
                            
                            DetailRow(
                                label: "Yatırım Ufku",
                                value: formatHorizon(profile.investmentHorizon),
                                color: AppColors.primary
                            )
                            
                            if !profile.preferredSectors.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Tercih Edilen Sektörler")
                                        .font(.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                    
                                    LazyVGrid(columns: [
                                        GridItem(.adaptive(minimum: 100))
                                    ], spacing: 8) {
                                        ForEach(profile.preferredSectors, id: \.self) { sector in
                                            Text("#\(formatSector(sector))")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(AppColors.primary)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    Capsule()
                                                        .fill(AppColors.primary.opacity(0.1))
                                                )
                                        }
                                    }
                                }
                                .padding()
                                .background(AppColors.cardBackground)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 50)
                    }
                }
            }
            .navigationTitle("Yatırımcı Profili Detayı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }
    
    private func getRiskColor(_ risk: String) -> Color {
        switch risk.uppercased() {
        case "LOW":
            return .green
        case "MEDIUM":
            return .orange
        case "HIGH":
            return .red
        default:
            return AppColors.textSecondary
        }
    }
    
    private func formatHorizon(_ horizon: String) -> String {
        switch horizon.uppercased() {
        case "SHORT_TERM":
            return "Kısa Vadeli"
        case "MEDIUM_TERM":
            return "Orta Vadeli"
        case "LONG_TERM":
            return "Uzun Vadeli"
        default:
            return horizon
        }
    }
    
    private func formatSector(_ sector: String) -> String {
        let sectorMap: [String: String] = [
            "technology": "Teknoloji",
            "healthcare": "Sağlık",
            "financials": "Finans",
            "consumer_staples": "Tüketim",
            "energy": "Enerji",
            "utilities": "Altyapı",
            "industrials": "Endüstri",
            "materials": "Malzeme",
            "real_estate": "Gayrimenkul",
            "communication": "İletişim"
        ]
        return sectorMap[sector.lowercased()] ?? sector.capitalized
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppColors.primary)
            Text(title)
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            Spacer()
        }
    }
}

struct PortfolioAllocationRow: View {
    let title: String
    let percentage: Int
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color.opacity(0.1))
                            .frame(height: 20)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: CGFloat(percentage) * geometry.size.width / 100, height: 20)
                    }
                }
                .frame(height: 20)
            }
            
            Text("\(percentage)%")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(12)
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