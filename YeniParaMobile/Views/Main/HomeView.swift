import SwiftUI
import Combine

// MARK: - Stock Navigation
struct StockNavigation: Identifiable, Hashable {
    let id = UUID()
    let symbol: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(symbol)
    }
    
    static func == (lhs: StockNavigation, rhs: StockNavigation) -> Bool {
        lhs.id == rhs.id && lhs.symbol == rhs.symbol
    }
}

// MARK: - Main Home View
struct HomeView: View {
    @ObservedObject var authVM: AuthViewModel
    @EnvironmentObject var navigationManager: NavigationManager
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedFilter: FilterType = .all
    @State private var followedStocks: Set<String> = []
    @State private var showingFollowed = false
    
    // For investor profile matching
    @State private var userInvestorProfile: String = "moderate" // This should come from authVM
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Simple Header
                VStack(spacing: 12) {
                    HStack {
                        Text("Piyasalar")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        // Market Status
                        MarketStatusIndicator()
                        
                        Button(action: { Task { await viewModel.refreshData() } }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title2)
                                .foregroundColor(AppColors.primary)
                                .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                                .animation(viewModel.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // 15 minute delay banner
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption)
                        Text("Veriler 15 dakika gecikmeli")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(AppColors.warning.opacity(0.1))
                            .overlay(
                                Capsule()
                                    .stroke(AppColors.warning.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 10)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Search Bar with modern design
                        ModernSearchBar(text: $viewModel.searchText)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        // Modern Filter Pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(FilterType.allCases, id: \.self) { filter in
                                    HomeFilterChip(
                                        filter: filter,
                                        isSelected: selectedFilter == filter,
                                        count: getFilterCount(for: filter)
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            selectedFilter = filter
                                            viewModel.selectedFilter = filter
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Top Movers Section
                        if selectedFilter == .all && viewModel.searchText.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("En Çok Kazananlar")
                                        .font(.headline)
                                        .foregroundColor(AppColors.textPrimary)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(viewModel.topGainers.prefix(5), id: \.code) { stock in
                                            CompactStockCard(stock: stock) {
                                                navigationManager.navigateToStock(stock.code)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                                
                                HStack {
                                    Text("En Çok Kaybedenler")
                                        .font(.headline)
                                        .foregroundColor(AppColors.textPrimary)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(viewModel.topLosers.prefix(5), id: \.code) { stock in
                                            CompactStockCard(stock: stock) {
                                                navigationManager.navigateToStock(stock.code)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        
                        // Modern Stocks List
                        ModernStocksListSection(
                            stocks: viewModel.filteredStocks,
                            favoriteStocks: followedStocks,
                            isLoading: viewModel.isLoading && viewModel.stocks.isEmpty,
                            searchText: viewModel.searchText,
                            authToken: authVM.accessToken,
                            userProfile: userInvestorProfile,
                            onNavigateToStock: { stockCode in
                                // Debug logging removed for production
                                navigationManager.navigateToStock(stockCode)
                            },
                            onFavoriteToggle: toggleFollowStock
                        )
                    }
                    .padding(.bottom, 100)
                }
            }
            
            // Error Banner
            if viewModel.showError {
                VStack {
                    ErrorBanner(
                        message: viewModel.errorMessage,
                        onRetry: {
                            Task { await viewModel.refreshData() }
                        }
                    )
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingFollowed) {
            HomeFavoritesSheet(
                favoriteStocks: followedStocks,
                allStocks: viewModel.stocks,
                onNavigateToStock: { stockCode in
                    showingFollowed = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        navigationManager.navigateToStock(stockCode)
                    }
                },
                onRemoveFavorite: { stockCode in
                    toggleFollowStock(stockCode)
                }
            )
        }
        .sheet(isPresented: $navigationManager.showStockDetail, onDismiss: {
            // Reload followed stocks when returning from stock detail
            loadFollowedStocks()
        }) {
            if let symbol = navigationManager.selectedStock {
                SymbolDetailView(symbol: symbol)
                    .interactiveDismissDisabled(false)
            }
        }
        .onAppear {
            Task {
                await viewModel.loadData()
                // Start auto refresh after initial load
                viewModel.startAutoRefresh()
            }
            loadFollowedStocks()
            loadUserProfile()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Reload followed stocks when app becomes active
            loadFollowedStocks()
        }
    }
    
    // MARK: - Helper Functions
    private func toggleFollowStock(_ stockCode: String) {
        // Optimistically update UI first
        let wasFollowing = followedStocks.contains(stockCode)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if wasFollowing {
                followedStocks.remove(stockCode)
            } else {
                followedStocks.insert(stockCode)
            }
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Then make API call
        Task {
            do {
                if wasFollowing {
                    // Unfollow
                    let response = try await APIService.shared.unfollowStock(symbol: stockCode)
                    if !response.success {
                        // Revert on failure
                        await MainActor.run {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                followedStocks.insert(stockCode)
                            }
                        }
                    }
                } else {
                    // Follow
                    let response = try await APIService.shared.followStock(symbol: stockCode)
                    if !response.success {
                        // Revert on failure
                        await MainActor.run {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                followedStocks.remove(stockCode)
                            }
                        }
                    }
                }
            } catch {
                print("Error toggling follow status: \(error)")
                // Revert on error
                await MainActor.run {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        if wasFollowing {
                            followedStocks.insert(stockCode)
                        } else {
                            followedStocks.remove(stockCode)
                        }
                    }
                }
            }
        }
    }
    
    private func loadFollowedStocks() {
        Task {
            do {
                let response = try await APIService.shared.getFollowedStocks()
                if response.success {
                    await MainActor.run {
                        followedStocks = Set(response.data.stocks.map { $0.symbolCode })
                    }
                }
            } catch {
                print("Error loading followed stocks: \(error)")
            }
        }
    }
    
    private func loadUserProfile() {
        if let profile = authVM.investorProfile {
            userInvestorProfile = profile.riskTolerance.lowercased()
        } else {
            userInvestorProfile = "moderate"
        }
    }
    
    private func getFilterCount(for filter: FilterType) -> Int {
        switch filter {
        case .all:
            return viewModel.stocks.count
        case .popular:
            return min(50, viewModel.stocks.count)
        case .gainers:
            return viewModel.stocks.filter { $0.changePercent > 0 }.count
        case .losers:
            return viewModel.stocks.filter { $0.changePercent < 0 }.count
        case .favorites:
            return followedStocks.count
        }
    }
}

// MARK: - Modern Header Component
struct ModernHomeHeader: View {
    let favoriteCount: Int
    let isLoading: Bool
    let onFavoritesAction: () -> Void
    let onRefreshAction: () -> Void
    let onSearchTap: () -> Void
    
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 6..<12:
            return "Günaydın 🌅"
        case 12..<17:
            return "İyi günler ☀️"
        case 17..<22:
            return "İyi akşamlar 🌆"
        default:
            return "İyi geceler 🌙"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Section with gradient background
            ZStack {
                LinearGradient(
                    colors: [
                        AppColors.primary.opacity(0.1),
                        AppColors.background
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
                .ignoresSafeArea(edges: .top)
                
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(greeting)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                            
                            Text("Piyasalar")
                                .font(.system(size: 34, weight: .black, design: .rounded))
                                .foregroundColor(AppColors.textPrimary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            // Notification Button
                            Button(action: {}) {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "bell")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(AppColors.textPrimary)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(AppColors.cardBackground)
                                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                        )
                                    
                                    // Notification badge
                                    Circle()
                                        .fill(AppColors.error)
                                        .frame(width: 10, height: 10)
                                        .offset(x: -8, y: 8)
                                }
                            }
                            
                            // Favorites Button with modern badge
                            Button(action: onFavoritesAction) {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(AppColors.error)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(AppColors.error.opacity(0.1))
                                                .shadow(color: AppColors.error.opacity(0.2), radius: 8, x: 0, y: 4)
                                        )
                                    
                                    if favoriteCount > 0 {
                                        Text("\(favoriteCount)")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(minWidth: 18, minHeight: 18)
                                            .background(
                                                Circle()
                                                    .fill(AppColors.primary)
                                            )
                                            .offset(x: -6, y: 6)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 50)
                }
            }
            .frame(height: 120)
            
            // Live Status Bar
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Color.green.opacity(0.3), lineWidth: 8)
                                .scaleEffect(isLoading ? 2 : 1)
                                .opacity(isLoading ? 0 : 1)
                                .animation(.easeOut(duration: 1).repeatForever(autoreverses: false), value: isLoading)
                        )
                    
                    Text("Piyasalar Açık")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(Color.green.opacity(0.2), lineWidth: 1)
                        )
                )
                
                Spacer()
                
                // Refresh button with animation
                Button(action: onRefreshAction) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .semibold))
                            .rotationEffect(.degrees(isLoading ? 360 : 0))
                            .animation(
                                isLoading ?
                                .linear(duration: 1).repeatForever(autoreverses: false) :
                                .default,
                                value: isLoading
                            )
                        
                        Text(isLoading ? "Güncelleniyor..." : "Yenile")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(AppColors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(AppColors.primary.opacity(0.1))
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Rectangle()
                    .fill(AppColors.cardBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
            )
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
}

// MARK: - Modern Search Bar
struct ModernSearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(isFocused ? AppColors.primary : AppColors.textSecondary)
            
            TextField("Apple, Tesla, Google...", text: $text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
                .autocapitalization(.allCharacters)
                .focused($isFocused)
            
            if !text.isEmpty {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        text = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.textSecondary)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            
            if isFocused {
                Button("iptal") {
                    withAnimation(.spring(response: 0.3)) {
                        text = ""
                        isFocused = false
                    }
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.primary)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isFocused ? AppColors.primary : Color.clear,
                            lineWidth: 2
                        )
                )
                .shadow(
                    color: isFocused ? AppColors.primary.opacity(0.1) : Color.black.opacity(0.05),
                    radius: isFocused ? 10 : 5,
                    x: 0,
                    y: 4
                )
        )
        .animation(.spring(response: 0.3), value: isFocused)
    }
}

// MARK: - Home Filter Chip
struct HomeFilterChip: View {
    let filter: FilterType
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: filter.icon)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(filter.displayName)
                    .font(.system(size: 14, weight: .semibold))
                
                if count > 0 && filter != .all {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.2) : AppColors.primary.opacity(0.1))
                        )
                }
            }
            .foregroundColor(isSelected ? .white : AppColors.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.primary.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [AppColors.cardBackground, AppColors.cardBackground],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: isSelected ? AppColors.primary.opacity(0.3) : Color.black.opacity(0.05),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: 4
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Filter Pill Component
struct FilterPill: View {
    let filter: FilterType
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.system(size: 12, weight: .semibold))
                
                Text(filter.displayName)
                    .font(.system(size: 14, weight: .semibold))
                
                if count > 0 && filter != .all {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isSelected ? .black.opacity(0.7) : AppColors.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? .black.opacity(0.15) : AppColors.cardBackground)
                        )
                }
            }
            .foregroundColor(isSelected ? .black : AppColors.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? AppColors.primary : AppColors.cardBackground)
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? Color.clear : AppColors.cardBorder, lineWidth: 1)
                    )
            )
            .shadow(color: isSelected ? AppColors.primary.opacity(0.2) : Color.clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Home Featured Stocks Section
struct HomeFeaturedStocksSection: View {
    let topGainers: [UISymbol]
    let topLosers: [UISymbol]
    let favoriteStocks: Set<String>
    let userProfile: String
    let onNavigateToStock: (String) -> Void
    let onFavoriteToggle: (String) -> Void
    
    @State private var selectedTab = 0
    
    private var followedStocks: Set<String> {
        favoriteStocks
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("🔥 Öne Çıkanlar")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                // Tab selector
                HStack(spacing: 0) {
                    ForEach(0..<2) { index in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedTab = index
                            }
                        }) {
                            Text(index == 0 ? "Yükselenler" : "Düşenler")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(selectedTab == index ? .white : AppColors.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    selectedTab == index ?
                                    (index == 0 ? AppColors.primary : AppColors.error) :
                                    Color.clear
                                )
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(3)
                .background(AppColors.cardBackground)
                .cornerRadius(10)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if selectedTab == 0 {
                        ForEach(topGainers.prefix(5), id: \.code) { stock in
                            ModernStockCard(
                                stock: stock,
                                isGainer: true,
                                isFavorite: followedStocks.contains(stock.code),
                                matchScore: calculateMatchScore(for: stock, userProfile: userProfile),
                                onFavoriteToggle: {
                                    onFavoriteToggle(stock.code)
                                }
                            )
                            .onTapGesture {
                                onNavigateToStock(stock.code)
                            }
                        }
                    } else {
                        ForEach(topLosers.prefix(5), id: \.code) { stock in
                            ModernStockCard(
                                stock: stock,
                                isGainer: false,
                                isFavorite: followedStocks.contains(stock.code),
                                matchScore: calculateMatchScore(for: stock, userProfile: userProfile),
                                onFavoriteToggle: {
                                    onFavoriteToggle(stock.code)
                                }
                            )
                            .onTapGesture {
                                onNavigateToStock(stock.code)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Modern Stock Card
struct ModernStockCard: View {
    let stock: UISymbol
    let isGainer: Bool
    let isFavorite: Bool
    let matchScore: Int
    let onFavoriteToggle: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with gradient
            ZStack {
                LinearGradient(
                    colors: [
                        isGainer ? AppColors.primary : AppColors.error,
                        isGainer ? AppColors.primary.opacity(0.6) : AppColors.error.opacity(0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(stock.code)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(stock.name)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Button(action: onFavoriteToggle) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                }
                .padding(12)
            }
            .frame(height: 70)
            
            // Content
            VStack(spacing: 12) {
                // Logo
                StockLogoView(symbol: stock.code, logoPath: stock.logoPath, size: 60, authToken: nil)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.cardBorder.opacity(0.3), lineWidth: 1)
                    )
                
                // Price Info
                VStack(spacing: 6) {
                    Text(stock.formattedPrice)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: isGainer ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 12, weight: .bold))
                        
                        Text(stock.formattedChangePercent)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(stock.changeColor)
                }
                
                // Match Score
                HStack(spacing: 4) {
                    Circle()
                        .fill(matchScoreColor(matchScore))
                        .frame(width: 6, height: 6)
                    
                    Text("%\(matchScore) Uyumlu")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(AppColors.cardBackground)
                )
            }
            .padding(16)
            .frame(maxWidth: .infinity)
        }
        .frame(width: 160)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.cardBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
        )
        .scaleEffect(isPressed ? 0.95 : 1)
        .animation(.spring(response: 0.3), value: isPressed)
    }
    
    private func matchScoreColor(_ score: Int) -> Color {
        switch score {
        case 80...: return AppColors.primary
        case 60..<80: return Color.orange
        case 40..<60: return Color.yellow
        default: return Color.red
        }
    }
}

// MARK: - Top Movers Section
struct TopMoversSection: View {
    let topGainers: [UISymbol]
    let topLosers: [UISymbol]
    let favoriteStocks: Set<String>
    let userProfile: String
    let onNavigateToStock: (String) -> Void
    let onFavoriteToggle: (String) -> Void
    
    private var followedStocks: Set<String> {
        favoriteStocks
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Günün Yıldızları")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(topGainers.prefix(3), id: \.code) { stock in
                        HomeTopMoverCard(
                            stock: stock,
                            isGainer: true,
                            isFavorite: followedStocks.contains(stock.code),
                            matchScore: calculateMatchScore(for: stock, userProfile: userProfile),
                            onFavoriteToggle: {
                                onFavoriteToggle(stock.code)
                            }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Debug logging removed for production
                            onNavigateToStock(stock.code)
                        }
                    }
                    
                    ForEach(topLosers.prefix(2), id: \.code) { stock in
                        HomeTopMoverCard(
                            stock: stock,
                            isGainer: false,
                            isFavorite: followedStocks.contains(stock.code),
                            matchScore: calculateMatchScore(for: stock, userProfile: userProfile),
                            onFavoriteToggle: {
                                onFavoriteToggle(stock.code)
                            }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Debug logging removed for production
                            onNavigateToStock(stock.code)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Top Mover Card Component (HomeView Version)
struct HomeTopMoverCard: View {
    let stock: UISymbol
    let isGainer: Bool
    let isFavorite: Bool
    let matchScore: Int
    let onFavoriteToggle: () -> Void
    
    @State private var isPressed = false
    
    var cardGradient: LinearGradient {
        if isGainer {
            return LinearGradient(
                colors: [AppColors.primary.opacity(0.15), AppColors.primary.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [AppColors.error.opacity(0.15), AppColors.error.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var borderColor: Color {
        switch matchScore {
        case 80...:
            return AppColors.primary
        case 60..<80:
            return Color.orange
        case 40..<60:
            return Color.yellow
        default:
            return Color.red
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                // Match Score Badge with percentage
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(borderColor)
                    
                    Text("%\(matchScore)")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(borderColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(borderColor.opacity(0.2))
                        .overlay(
                            Capsule()
                                .stroke(borderColor.opacity(0.4), lineWidth: 1.5)
                        )
                )
                
                Spacer()
                
                // Favorite Button
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 14))
                    .foregroundColor(isFavorite ? AppColors.error : AppColors.textSecondary)
                    .onTapGesture {
                        onFavoriteToggle()
                    }
            }
            
            // Stock Logo and Info
            VStack(spacing: 8) {
                StockLogoView(symbol: stock.code, logoPath: stock.logoPath, size: 56, authToken: nil)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.cardBorder.opacity(0.3), lineWidth: 1)
                    )
                
                Text(stock.code)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(stock.name)
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            
            // Price Info
            VStack(spacing: 4) {
                Text(stock.formattedPrice)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: 4) {
                    Image(systemName: isGainer ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10))
                    
                    Text(stock.formattedChangePercent)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(stock.changeColor)
            }
            
            // Volume
            Text("Vol: \(stock.formattedVolume)")
                .font(.system(size: 10))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(16)
        .frame(width: 140)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(borderColor.opacity(0.6), lineWidth: 2.5)
                )
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

// MARK: - Modern Stocks List Section
struct ModernStocksListSection: View {
    let stocks: [UISymbol]
    let favoriteStocks: Set<String>
    let isLoading: Bool
    let searchText: String
    let authToken: String?
    let userProfile: String
    let onNavigateToStock: (String) -> Void
    let onFavoriteToggle: (String) -> Void
    
    private var followedStocks: Set<String> {
        favoriteStocks
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Text("Tüm Hisseler")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                if !stocks.isEmpty {
                    Text("\(stocks.count) hisse")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.horizontal, 20)
            
            // Stocks List
            LazyVStack(spacing: 12) {
                if isLoading {
                    ForEach(0..<10, id: \.self) { _ in
                        ModernLoadingRow()
                            .padding(.horizontal, 20)
                    }
                } else if stocks.isEmpty {
                    ModernEmptyState(searchText: searchText)
                        .frame(minHeight: 300)
                        .padding(.horizontal, 20)
                } else {
                    ForEach(stocks, id: \.code) { stock in
                        ModernStockRow(
                            stock: stock,
                            isFavorite: followedStocks.contains(stock.code),
                            authToken: authToken,
                            userProfile: userProfile,
                            onFavoriteToggle: {
                                onFavoriteToggle(stock.code)
                            }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onNavigateToStock(stock.code)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
        .padding(.top, 20)
    }
}

// MARK: - Modern Stock Row
struct ModernStockRow: View {
    let stock: UISymbol
    let isFavorite: Bool
    let authToken: String?
    let userProfile: String
    let onFavoriteToggle: () -> Void
    
    @State private var isPressed = false
    
    private var matchScore: Int {
        calculateMatchScore(for: stock, userProfile: userProfile)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Bigger logo without background with oval shape
            StockLogoView(symbol: stock.code, logoPath: stock.logoPath, size: 60, authToken: authToken)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.cardBorder.opacity(0.3), lineWidth: 1)
                )
            
            // Stock Info
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(stock.code)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    // Trend indicator
                    Image(systemName: stock.isPositive ? "flame.fill" : "snowflake")
                        .font(.system(size: 12))
                        .foregroundColor(stock.isPositive ? Color.orange : Color.blue)
                        .opacity(abs(stock.changePercent) > 5 ? 1 : 0)
                }
                
                Text(stock.name)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Price Section
            VStack(alignment: .trailing, spacing: 6) {
                Text(stock.formattedPrice)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: 4) {
                    Image(systemName: stock.isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                    
                    Text(stock.formattedChangePercent)
                        .font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(stock.changeColor.opacity(0.15))
                )
                .foregroundColor(stock.changeColor)
            }
            
            // Favorite Button
            Button(action: onFavoriteToggle) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 20))
                    .foregroundColor(isFavorite ? AppColors.error : AppColors.textTertiary)
                    .scaleEffect(isFavorite ? 1.1 : 1)
                    .animation(.spring(response: 0.3), value: isFavorite)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .scaleEffect(isPressed ? 0.98 : 1)
        .animation(.spring(response: 0.3), value: isPressed)
    }
    
    private func matchScoreColor(_ score: Int) -> Color {
        switch score {
        case 80...: return AppColors.primary
        case 60..<80: return Color.orange  
        case 40..<60: return Color.yellow
        default: return Color.red
        }
    }
}

// MARK: - Modern Loading Row
struct ModernLoadingRow: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 52, height: 52)
                .shimmer(isAnimating: isAnimating)
            
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 80, height: 16)
                    .shimmer(isAnimating: isAnimating)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 120, height: 12)
                    .shimmer(isAnimating: isAnimating)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 70, height: 16)
                    .shimmer(isAnimating: isAnimating)
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 60, height: 24)
                    .shimmer(isAnimating: isAnimating)
            }
            
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 20, height: 20)
                .shimmer(isAnimating: isAnimating)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cardBackground)
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Modern Empty State
struct ModernEmptyState: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: searchText.isEmpty ? "chart.line.uptrend.xyaxis.circle.fill" : "magnifyingglass.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(AppColors.primary.opacity(0.3))
            
            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "Henüz hisse yok" : "Sonuç bulunamadı")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(searchText.isEmpty ? "Veriler yükleniyor..." : "'\(searchText)' için sonuç bulunamadı")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Stocks List Section
struct StocksListSection: View {
    let stocks: [UISymbol]
    let favoriteStocks: Set<String>
    let isLoading: Bool
    let searchText: String
    let authToken: String?
    let userProfile: String
    let onNavigateToStock: (String) -> Void
    let onFavoriteToggle: (String) -> Void
    
    private var followedStocks: Set<String> {
        favoriteStocks
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Stocks
            LazyVStack(spacing: 8) {
                if isLoading {
                    ForEach(0..<10, id: \.self) { _ in
                        LoadingStockRow()
                            .padding(.horizontal, 20)
                    }
                } else if stocks.isEmpty {
                    EmptyStateView(searchText: searchText)
                        .frame(minHeight: 300)
                } else {
                    ForEach(stocks, id: \.code) { stock in
                        StockRowView(
                            stock: stock,
                            isFavorite: followedStocks.contains(stock.code),
                            authToken: authToken,
                            userProfile: userProfile,
                            onFavoriteToggle: {
                                onFavoriteToggle(stock.code)
                            }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Debug logging removed for production
                            onNavigateToStock(stock.code)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
        .padding(.top, 20)
    }
}

// MARK: - Stock Row View
struct StockRowView: View {
    let stock: UISymbol
    let isFavorite: Bool
    let authToken: String?
    let userProfile: String
    let onFavoriteToggle: () -> Void
    
    @State private var isPressed = false
    
    private var matchScore: Int {
        calculateMatchScore(for: stock, userProfile: userProfile)
    }
    
    private var matchScoreColor: Color {
        switch matchScore {
        case 80...:
            return AppColors.primary
        case 60..<80:
            return Color.orange
        case 40..<60:
            return Color.yellow
        default:
            return Color.red
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Left Section: Logo and Stock Info
            HStack(spacing: 12) {
                // Stock Logo without background with oval shape
                StockLogoView(
                    symbol: stock.code,
                    logoPath: stock.logoPath,
                    size: 60,
                    authToken: authToken
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.cardBorder.opacity(0.3), lineWidth: 1)
                )
                
                // Stock Code & Name
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(stock.code)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        
                        // Match Score Badge
                        HStack(spacing: 2) {
                            Text("%\(matchScore)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(matchScoreColor)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(matchScoreColor.opacity(0.15))
                        )
                    }
                    
                    Text(stock.name)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 8)
            
            // Right Section: Price and Change
            VStack(alignment: .trailing, spacing: 2) {
                Text(stock.formattedPrice)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .animation(.easeInOut(duration: 0.2), value: stock.price)
                    .id("price-\(stock.code)-\(stock.price)")
                
                HStack(spacing: 4) {
                    Image(systemName: stock.isPositive ? "arrow.up" : "arrow.down")
                        .font(.system(size: 9, weight: .bold))
                    
                    Text(stock.formattedChangePercent)
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(stock.changeColor)
                .animation(.easeInOut(duration: 0.2), value: stock.changePercent)
                .id("change-\(stock.code)-\(stock.changePercent)")
            }
            
            // Favorite Button
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 18))
                .foregroundColor(isFavorite ? AppColors.error : AppColors.textTertiary)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
                .onTapGesture {
                    onFavoriteToggle()
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isPressed ? AppColors.cardBackground.opacity(0.8) : AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}


// MARK: - Match Score Badge
struct MatchScoreBadge: View {
    let score: Int
    
    private var color: Color {
        switch score {
        case 80...:
            return AppColors.primary
        case 60..<80:
            return Color.orange
        case 40..<60:
            return Color.yellow
        default:
            return Color.red
        }
    }
    
    private var profileText: String {
        switch score {
        case 80...:
            return "Çok Uygun"
        case 60..<80:
            return "Uygun"
        case 40..<60:
            return "Orta"
        default:
            return "Riskli"
        }
    }
    
    var body: some View {
        HStack(spacing: 5) {
            // Match percentage
            Text("%\(score)")
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(color)
            
            // Divider
            Text("•")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color.opacity(0.7))
            
            // Profile match text
            Text(profileText)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(color.opacity(0.2))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.4), lineWidth: 1.5)
                )
        )
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "chart.line.uptrend.xyaxis" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textTertiary)
            
            Text(searchText.isEmpty ? "Henüz hisse yok" : "Sonuç bulunamadı")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            
            Text(searchText.isEmpty ? "Veriler yükleniyor..." : "Başka bir arama yapmayı deneyin")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Loading Stock Row
struct LoadingStockRow: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Logo placeholder
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.1))
                .frame(width: 44, height: 44)
                .shimmer(isAnimating: isAnimating)
            
            // Info placeholder
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 60, height: 14)
                    .shimmer(isAnimating: isAnimating)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 120, height: 10)
                    .shimmer(isAnimating: isAnimating)
            }
            
            Spacer()
            
            // Price placeholder
            VStack(alignment: .trailing, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 70, height: 14)
                    .shimmer(isAnimating: isAnimating)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 50, height: 12)
                    .shimmer(isAnimating: isAnimating)
            }
            
            // Button placeholder
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 18, height: 18)
                .shimmer(isAnimating: isAnimating)
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackground)
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Error Banner
struct ErrorBanner: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.orange)
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(2)
            
            Spacer()
            
            Button("Tekrar Dene") {
                onRetry()
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(AppColors.primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// MARK: - Shimmer Effect
extension View {
    func shimmer(isAnimating: Bool) -> some View {
        self.overlay(
            GeometryReader { geometry in
                if isAnimating {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.1),
                            Color.white.opacity(0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: -geometry.size.width)
                    .offset(x: geometry.size.width * 2)
                    .animation(
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                }
            }
        )
        .clipped()
    }
}

// MARK: - Match Score Calculation
func calculateMatchScore(for stock: UISymbol, userProfile: String) -> Int {
    let stockCode = stock.code.lowercased()
    
    let profileScores: [String: [String: Int]] = [
        "conservative": [
            "jnj": 95, "ko": 92, "pfe": 88, "pg": 90, "jpm": 85,
            "wmt": 87, "vz": 86, "t": 84, "mmm": 83, "xom": 80,
            "aapl": 65, "msft": 68, "googl": 60, "amzn": 55, "tsla": 30,
            "nvda": 35, "meta": 40, "nflx": 38, "coin": 20, "riot": 15
        ],
        "moderate": [
            "aapl": 85, "msft": 88, "googl": 82, "amzn": 80, "jpm": 78,
            "v": 83, "ma": 82, "hd": 75, "dis": 77, "nke": 74,
            "jnj": 70, "ko": 68, "pfe": 65, "wmt": 72, "pg": 71,
            "tsla": 60, "nvda": 65, "meta": 63, "nflx": 58, "coin": 40
        ],
        "growth": [
            "aapl": 90, "msft": 92, "googl": 88, "amzn": 91, "tsla": 85,
            "nvda": 93, "meta": 87, "nflx": 82, "crm": 86, "adbe": 84,
            "v": 78, "ma": 77, "pypl": 80, "sq": 83, "shop": 81,
            "jnj": 50, "ko": 45, "pfe": 48, "xom": 40, "t": 35
        ],
        "aggressive": [
            "tsla": 95, "nvda": 98, "coin": 90, "riot": 88, "mara": 87,
            "pltr": 92, "nio": 85, "lcid": 83, "rivn": 82, "sofi": 86,
            "meta": 80, "nflx": 78, "arkk": 94, "spce": 89, "gme": 91,
            "jnj": 20, "ko": 15, "pfe": 25, "xom": 30, "t": 18
        ]
    ]
    
    let scores = profileScores[userProfile.lowercased()] ?? profileScores["moderate"]!
    
    if let score = scores[stockCode] {
        return score
    }
    
    let volatilityFactor = abs(stock.changePercent)
    let volumeFactor = Double(stock.volume) / 10_000_000
    
    var baseScore: Int
    switch userProfile.lowercased() {
    case "conservative":
        baseScore = volatilityFactor < 1 ? 70 : volatilityFactor < 3 ? 50 : 30
    case "moderate":
        baseScore = volatilityFactor < 2 ? 60 : volatilityFactor < 5 ? 70 : 50
    case "growth":
        baseScore = volatilityFactor > 2 ? 75 : volatilityFactor > 5 ? 85 : 60
    case "aggressive":
        baseScore = volatilityFactor > 3 ? 85 : volatilityFactor > 7 ? 95 : 65
    default:
        baseScore = 50
    }
    
    if volumeFactor > 5 {
        baseScore += 5
    }
    
    return min(100, max(0, baseScore))
}

// MARK: - Favorites Sheet (HomeView Version)
struct HomeFavoritesSheet: View {
    let favoriteStocks: Set<String>
    let allStocks: [UISymbol]
    let onNavigateToStock: (String) -> Void
    let onRemoveFavorite: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private var favoriteStocksList: [UISymbol] {
        allStocks.filter { favoriteStocks.contains($0.code) }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if favoriteStocksList.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "heart.slash")
                                .font(.system(size: 64))
                                .foregroundColor(AppColors.textTertiary)
                            
                            Text("Favorileriniz Boş")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Beğendiğiniz hisseleri kalp butonuna tıklayarak favorilerinize ekleyebilirsiniz.")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(favoriteStocksList, id: \.code) { stock in
                                    HomeFavoriteStockRow(
                                        stock: stock,
                                        onRemove: {
                                            onRemoveFavorite(stock.code)
                                        }
                                    )
                                    .onTapGesture {
                                        // Navigate to stock detail
                                        onNavigateToStock(stock.code)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        }
                    }
                }
            }
            .navigationTitle("Favorilerim")
            .navigationBarTitleDisplayMode(.large)
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
}

// MARK: - Favorite Stock Row (HomeView Version)
struct HomeFavoriteStockRow: View {
    let stock: UISymbol
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Stock Logo/Icon
            StockLogoView(symbol: stock.code, logoPath: stock.logoPath, size: 56, authToken: nil)
            
            // Stock Info
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.code)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(stock.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Price Info
            VStack(alignment: .trailing, spacing: 4) {
                Text(stock.formattedPrice)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: 4) {
                    Image(systemName: stock.isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10))
                    
                    Text(stock.formattedChangePercent)
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(stock.changeColor)
            }
            
            // Remove Button
            Image(systemName: "heart.fill")
                .font(.system(size: 16))
                .foregroundColor(AppColors.error)
                .frame(width: 32, height: 32)
                .background(AppColors.error.opacity(0.1))
                .clipShape(Circle())
                .onTapGesture {
                    onRemove()
                }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Compact Stock Card
struct CompactStockCard: View {
    let stock: UISymbol
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(stock.code)
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: stock.isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                        .foregroundColor(stock.isPositive ? AppColors.success : AppColors.error)
                }
                
                Text(stock.name)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
                
                HStack {
                    Text(stock.formattedPrice)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Text(stock.formattedChangePercent)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(stock.isPositive ? AppColors.success : AppColors.error)
                }
            }
            .padding(12)
            .frame(width: 150)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(stock.isPositive ? AppColors.success.opacity(0.3) : AppColors.error.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HomeView(authVM: AuthViewModel())
        }
        .preferredColorScheme(.dark)
    }
}
