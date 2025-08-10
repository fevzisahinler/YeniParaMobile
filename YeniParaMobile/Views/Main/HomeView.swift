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
    @State private var favoriteStocks: Set<String> = []
    @State private var showingFavorites = false
    
    // For investor profile matching
    @State private var userInvestorProfile: String = "moderate" // This should come from authVM
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HomeHeaderView(
                    favoriteCount: favoriteStocks.count,
                    isLoading: viewModel.isLoading,
                    onFavoritesAction: { showingFavorites = true },
                    onRefreshAction: { Task { await viewModel.refreshData() } }
                )
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Search Bar
                        HomeSearchBar(text: $viewModel.searchText)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        
                        // Filter Pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(FilterType.allCases, id: \.self) { filter in
                                    FilterPill(
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
                        
                        // Top Movers - Only show on "all" filter with no search
                        if selectedFilter == .all && viewModel.searchText.isEmpty && !viewModel.topGainers.isEmpty {
                            TopMoversSection(
                                topGainers: viewModel.topGainers,
                                topLosers: viewModel.topLosers,
                                favoriteStocks: favoriteStocks,
                                userProfile: userInvestorProfile,
                                onNavigateToStock: { stockCode in
                                    print("DEBUG: HomeView - onNavigateToStock called with: \(stockCode)")
                                    let symbol = stockCode.contains(".") ? stockCode : "\(stockCode).US"
                                    print("DEBUG: HomeView - Formatted symbol: \(symbol)")
                                    navigationManager.navigateToStock(symbol)
                                    print("DEBUG: HomeView - navigationManager.showStockDetail: \(navigationManager.showStockDetail)")
                                },
                                onFavoriteToggle: toggleFavorite
                            )
                        }
                        
                        // Stocks List
                        StocksListSection(
                            stocks: viewModel.filteredStocks,
                            favoriteStocks: favoriteStocks,
                            isLoading: viewModel.isLoading && viewModel.stocks.isEmpty,
                            searchText: viewModel.searchText,
                            authToken: authVM.accessToken,
                            userProfile: userInvestorProfile,
                            onNavigateToStock: { stockCode in
                                print("DEBUG: StocksList - onNavigateToStock called with: \(stockCode)")
                                let symbol = stockCode.contains(".") ? stockCode : "\(stockCode).US"
                                print("DEBUG: StocksList - Formatted symbol: \(symbol)")
                                navigationManager.navigateToStock(symbol)
                                print("DEBUG: StocksList - navigationManager.showStockDetail: \(navigationManager.showStockDetail)")
                            },
                            onFavoriteToggle: toggleFavorite
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
        .sheet(isPresented: $showingFavorites) {
            HomeFavoritesSheet(
                favoriteStocks: favoriteStocks,
                allStocks: viewModel.stocks,
                onNavigateToStock: { stockCode in
                    showingFavorites = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        let symbol = stockCode.contains(".") ? stockCode : "\(stockCode).US"
                        navigationManager.navigateToStock(symbol)
                    }
                },
                onRemoveFavorite: { stockCode in
                    toggleFavorite(stockCode)
                }
            )
        }
        .sheet(isPresented: $navigationManager.showStockDetail) {
            if let symbol = navigationManager.selectedStock {
                SymbolDetailView(symbol: symbol)
            }
        }
        .onAppear {
            Task {
                await viewModel.loadData()
            }
            loadFavorites()
            loadUserProfile()
        }
    }
    
    // MARK: - Helper Functions
    private func toggleFavorite(_ stockCode: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if favoriteStocks.contains(stockCode) {
                favoriteStocks.remove(stockCode)
            } else {
                favoriteStocks.insert(stockCode)
            }
            saveFavorites()
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteStocks), forKey: "favoriteStocks")
    }
    
    private func loadFavorites() {
        if let saved = UserDefaults.standard.stringArray(forKey: "favoriteStocks") {
            favoriteStocks = Set(saved)
        }
    }
    
    private func loadUserProfile() {
        userInvestorProfile = "moderate"
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
            return favoriteStocks.count
        }
    }
}

// MARK: - Enhanced Header Component
struct HomeHeaderView: View {
    let favoriteCount: Int
    let isLoading: Bool
    let onFavoritesAction: () -> Void
    let onRefreshAction: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Piyasalar")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                            .scaleEffect(isLoading ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isLoading)
                        
                        Text("Canlı Fiyatlar")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    // Favorites Button with Badge
                    Button(action: onFavoritesAction) {
                        ZStack(alignment: .topTrailing) {
                            Circle()
                                .fill(AppColors.cardBackground)
                                .frame(width: 42, height: 42)
                                .overlay(
                                    Circle()
                                        .stroke(AppColors.cardBorder, lineWidth: 1)
                                )
                                .overlay(
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(AppColors.error)
                                )
                            
                            if favoriteCount > 0 {
                                Text("\(favoriteCount)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(minWidth: 16, minHeight: 16)
                                    .background(AppColors.error)
                                    .clipShape(Circle())
                                    .offset(x: 4, y: -4)
                            }
                        }
                    }
                    
                    // Refresh Button
                    Button(action: onRefreshAction) {
                        Circle()
                            .fill(AppColors.cardBackground)
                            .frame(width: 42, height: 42)
                            .overlay(
                                Circle()
                                    .stroke(AppColors.cardBorder, lineWidth: 1)
                            )
                            .overlay(
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                                    .rotationEffect(.degrees(isLoading ? 360 : 0))
                                    .animation(
                                        isLoading ?
                                        .linear(duration: 1).repeatForever(autoreverses: false) :
                                        .default,
                                        value: isLoading
                                    )
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(AppColors.background)
    }
}

// MARK: - Search Bar Component
struct HomeSearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
            
            TextField("Hisse ara...", text: $text)
                .font(.system(size: 16))
                .foregroundColor(AppColors.textPrimary)
                .autocapitalization(.allCharacters)
                .focused($isFocused)
            
            if !text.isEmpty {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        text = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFocused ? AppColors.primary : AppColors.cardBorder, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
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

// MARK: - Top Movers Section
struct TopMoversSection: View {
    let topGainers: [UISymbol]
    let topLosers: [UISymbol]
    let favoriteStocks: Set<String>
    let userProfile: String
    let onNavigateToStock: (String) -> Void
    let onFavoriteToggle: (String) -> Void
    
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
                            isFavorite: favoriteStocks.contains(stock.code),
                            matchScore: calculateMatchScore(for: stock, userProfile: userProfile),
                            onFavoriteToggle: {
                                onFavoriteToggle(stock.code)
                            }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            print("DEBUG: Top gainer tapped: \(stock.code)")
                            onNavigateToStock(stock.code)
                        }
                    }
                    
                    ForEach(topLosers.prefix(2), id: \.code) { stock in
                        HomeTopMoverCard(
                            stock: stock,
                            isGainer: false,
                            isFavorite: favoriteStocks.contains(stock.code),
                            matchScore: calculateMatchScore(for: stock, userProfile: userProfile),
                            onFavoriteToggle: {
                                onFavoriteToggle(stock.code)
                            }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            print("DEBUG: Top loser tapped: \(stock.code)")
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
                AsyncImage(url: URL(string: "http://192.168.1.210:4000\(stock.logoPath)")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.secondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text(String(stock.code.prefix(2)))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                
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
                            isFavorite: favoriteStocks.contains(stock.code),
                            authToken: authToken,
                            userProfile: userProfile,
                            onFavoriteToggle: {
                                onFavoriteToggle(stock.code)
                            }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            print("DEBUG: Stock tapped: \(stock.code)")
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
                // Stock Logo
                StockLogoView(
                    logoPath: stock.logoPath,
                    stockCode: stock.code,
                    authToken: authToken
                )
                .frame(width: 44, height: 44)
                
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
                
                HStack(spacing: 4) {
                    Image(systemName: stock.isPositive ? "arrow.up" : "arrow.down")
                        .font(.system(size: 9, weight: .bold))
                    
                    Text(stock.formattedChangePercent)
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(stock.changeColor)
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

// MARK: - Stock Logo View
struct StockLogoView: View {
    let logoPath: String
    let stockCode: String
    let authToken: String?
    
    @State private var logoData: Data?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if let logoData = logoData, let uiImage = UIImage(data: logoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else if isLoading {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.cardBackground)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                            .scaleEffect(0.6)
                    )
            } else {
                // Fallback logo
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary.opacity(0.8), AppColors.secondary.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Text(String(stockCode.prefix(2)))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
        }
        .onAppear {
            loadLogo()
        }
    }
    
    private func loadLogo() {
        guard let token = authToken else {
            isLoading = false
            return
        }
        
        Task {
            do {
                let url = URL(string: "http://192.168.1.210:4000\(logoPath)")!
                var request = URLRequest(url: url)
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.setValue("iOS", forHTTPHeaderField: "X-Platform")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    await MainActor.run {
                        self.logoData = data
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
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
            AsyncImage(url: URL(string: "http://192.168.1.210:4000\(stock.logoPath)")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.primary, AppColors.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text(String(stock.code.prefix(2)))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())
            
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

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HomeView(authVM: AuthViewModel())
        }
        .preferredColorScheme(.dark)
    }
}
