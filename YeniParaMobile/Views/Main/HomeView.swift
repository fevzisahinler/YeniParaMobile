import SwiftUI
import Combine

struct HomeView: View {
    @ObservedObject var authVM: AuthViewModel
    @StateObject private var viewModel = HomeViewModel()
    @State private var searchText = ""
    @State private var selectedFilter: FilterType = .all
    @State private var favoriteStocks: Set<String> = []
    @State private var showingFavorites = false
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerSection
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        searchSection
                        
                        if !viewModel.topGainers.isEmpty || !viewModel.topLosers.isEmpty {
                            topMoversSection
                        }
                        
                        stocksList
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
                .refreshable {
                    await viewModel.refreshData()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.loadData()
            }
            loadFavorites()
        }
        .onChange(of: searchText) { newValue in
            viewModel.searchText = newValue
        }
        .onChange(of: selectedFilter) { newValue in
            viewModel.selectedFilter = newValue
        }
        .overlay(
            Group {
                if viewModel.showError {
                    errorOverlay
                }
            }
        )
        .sheet(isPresented: $showingFavorites) {
            FavoritesSheet(
                favoriteStocks: favoriteStocks,
                allStocks: viewModel.stocks,
                onRemoveFavorite: { stockCode in
                    toggleFavorite(stockCode)
                }
            )
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hisse Senetleri")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        
                        Text("Canlı Fiyatlar")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Favorites Button
                    Button(action: {
                        showingFavorites = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(AppColors.cardBackground)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(AppColors.cardBorder, lineWidth: 1)
                                )
                            
                            Image(systemName: "heart.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(AppColors.primary)
                            
                            if !favoriteStocks.isEmpty {
                                Text("\(favoriteStocks.count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(minWidth: 16, minHeight: 16)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 14, y: -14)
                            }
                        }
                    }
                    
                    // Refresh Button
                    Button(action: {
                        Task {
                            await viewModel.refreshData()
                        }
                    }) {
                        Circle()
                            .fill(AppColors.cardBackground)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(AppColors.cardBorder, lineWidth: 1)
                            )
                            .overlay(
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                                    .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                                    .animation(
                                        viewModel.isLoading ?
                                        .linear(duration: 1).repeatForever(autoreverses: false) :
                                        .default,
                                        value: viewModel.isLoading
                                    )
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(AppColors.background)
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        VStack(spacing: 20) {
            // Search Bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                
                TextField("Hisse ara...", text: $searchText)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textPrimary)
                    .autocapitalization(.allCharacters)
                
                if !searchText.isEmpty {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            searchText = ""
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(AppColors.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.cardBorder, lineWidth: 1)
            )
            
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FilterType.allCases, id: \.self) { filter in
                        ModernFilterChip(
                            title: filter.displayName,
                            icon: filter.icon,
                            isSelected: selectedFilter == filter,
                            count: getFilterCount(for: filter)
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFilter = filter
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Top Movers Section
    private var topMoversSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Günün Yıldızları")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedFilter = .gainers
                    }
                }) {
                    HStack(spacing: 6) {
                        Text("Tümünü Gör")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.topGainers.prefix(3), id: \.code) { stock in
                        NavigationLink(destination: SymbolDetailView(symbol: stock.code)) {
                            TopMoverCard(
                                stock: stock,
                                isGainer: true,
                                isFavorite: favoriteStocks.contains(stock.code),
                                matchScore: calculateMatchScore(for: stock)
                            ) {
                                toggleFavorite(stock.code)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    ForEach(viewModel.topLosers.prefix(2), id: \.code) { stock in
                        NavigationLink(destination: SymbolDetailView(symbol: stock.code)) {
                            TopMoverCard(
                                stock: stock,
                                isGainer: false,
                                isFavorite: favoriteStocks.contains(stock.code),
                                matchScore: calculateMatchScore(for: stock)
                            ) {
                                toggleFavorite(stock.code)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Stocks List
    private var stocksList: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Hisseler")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text("\(viewModel.filteredStocks.count) hisse")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppColors.cardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.cardBorder, lineWidth: 1)
                    )
            }
            .padding(.horizontal, 20)
            
            if viewModel.isLoading && viewModel.stocks.isEmpty {
                LoadingView(message: "Hisse verileri yükleniyor...")
                    .frame(height: 200)
            } else if viewModel.filteredStocks.isEmpty {
                emptyView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredStocks, id: \.code) { stock in
                        NavigationLink(destination: SymbolDetailView(symbol: stock.code)) {
                            EnhancedStockRow(
                                stock: stock,
                                isFavorite: favoriteStocks.contains(stock.code),
                                matchScore: calculateMatchScore(for: stock)
                            ) {
                                toggleFavorite(stock.code)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Empty View
    private var emptyView: some View {
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
    
    // MARK: - Error Overlay
    private var errorOverlay: some View {
        VStack(spacing: 24) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundColor(AppColors.error)
            
            VStack(spacing: 8) {
                Text("Bağlantı Hatası")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(viewModel.errorMessage)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: {
                Task {
                    await viewModel.refreshData()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Tekrar Dene")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(AppColors.primary)
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.opacity(0.95))
        .edgesIgnoringSafeArea(.all)
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
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
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
    
    private func calculateMatchScore(for stock: UISymbol) -> Int {
        let baseScore = 50
        let volatilityFactor = min(abs(stock.changePercent) * 2, 20)
        let volumeFactor = stock.volume > 1_000_000 ? 10 : 5
        let trendFactor = stock.isPositive ? 15 : -5
        let priceStabilityFactor = stock.price > 10 ? 10 : 0
        
        let totalScore = baseScore + Int(volatilityFactor) + volumeFactor + trendFactor + priceStabilityFactor
        return min(max(totalScore, 0), 100)
    }
    
    private func getFilterCount(for filter: FilterType) -> Int {
        switch filter {
        case .all:
            return viewModel.stocks.count
        case .popular:
            return min(50, viewModel.stocks.count)
        case .gainers:
            return viewModel.stocks.filter { $0.changePercent > 0 }.count
        case .favorites:
            return favoriteStocks.count
        }
    }
}

// MARK: - Favorites Sheet
struct FavoritesSheet: View {
    let favoriteStocks: Set<String>
    let allStocks: [UISymbol]
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
                                    NavigationLink(destination: SymbolDetailView(symbol: stock.code)) {
                                        FavoriteStockRow(
                                            stock: stock,
                                            onRemove: {
                                                onRemoveFavorite(stock.code)
                                            }
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
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
            .navigationBarBackground(AppColors.background)
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

// MARK: - Favorite Stock Row
struct FavoriteStockRow: View {
    let stock: UISymbol
    let onRemove: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Logo with AsyncImage
            AsyncImage(url: URL(string: "http://localhost:4000\(stock.logoPath)")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppColors.primary.opacity(0.2),
                                    AppColors.primary.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text(stock.code.prefix(2))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            .frame(width: 48, height: 48)
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.code)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(stock.name)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(stock.formattedPrice)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: 4) {
                    Image(systemName: stock.isPositive ? "arrow.up" : "arrow.down")
                        .font(.system(size: 10, weight: .bold))
                    
                    Text(stock.formattedChangePercent)
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(stock.changeColor)
            }
            
            Button(action: onRemove) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.error)
            }
            .padding(.leading, 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Modern Filter Chip Component
struct ModernFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(icon)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isSelected ? .black.opacity(0.7) : AppColors.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(isSelected ? .black.opacity(0.15) : AppColors.cardBackground)
                        )
                }
            }
            .foregroundColor(isSelected ? .black : AppColors.textPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isSelected ? AppColors.primary : AppColors.cardBackground)
                    .shadow(color: isSelected ? AppColors.primary.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 2)
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? Color.clear : AppColors.cardBorder,
                        lineWidth: 1
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Top Mover Card
struct TopMoverCard: View {
    let stock: UISymbol
    let isGainer: Bool
    let isFavorite: Bool
    let matchScore: Int
    let onFavoriteTap: () -> Void
    
    private var matchColor: Color {
        if matchScore >= 80 { return AppColors.primary }
        if matchScore >= 60 { return .orange }
        return AppColors.error
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(stock.code)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(matchColor)
                            .frame(width: 6, height: 6)
                        
                        Text("\(matchScore)% uyum")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(matchColor)
                    }
                }
                
                Spacer()
                
                Button(action: onFavoriteTap) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 16))
                        .foregroundColor(isFavorite ? AppColors.error : AppColors.textSecondary)
                        .scaleEffect(isFavorite ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isFavorite)
                }
            }
            
            // Logo
            AsyncImage(url: URL(string: "http://localhost:4000\(stock.logoPath)")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.cardBackground)
                    
                    Text(stock.code.prefix(2))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            .frame(width: 32, height: 32)
            .cornerRadius(8)
            
            Text(stock.name)
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(stock.formattedPrice)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: 4) {
                    Image(systemName: isGainer ? "arrow.up" : "arrow.down")
                        .font(.system(size: 12, weight: .bold))
                    
                    Text(stock.formattedChangePercent)
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(isGainer ? AppColors.primary : AppColors.error)
            }
        }
        .padding(16)
        .frame(width: 160)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )
        )
    }
}

// MARK: - Enhanced Stock Row
struct EnhancedStockRow: View {
    let stock: UISymbol
    let isFavorite: Bool
    let matchScore: Int
    let onFavoriteTap: () -> Void
    
    @State private var isPressed = false
    
    private var matchColor: Color {
        if matchScore >= 80 { return AppColors.primary }
        if matchScore >= 60 { return .orange }
        return AppColors.error
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Match indicator - left border
            Rectangle()
                .fill(matchColor)
                .frame(width: 4)
                .cornerRadius(2, corners: [.topLeft, .bottomLeft])
            
            HStack(spacing: 16) {
                // Stock logo & info
                HStack(spacing: 12) {
                    // Logo with AsyncImage
                    AsyncImage(url: URL(string: "http://localhost:4000\(stock.logoPath)")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.cardBorder, lineWidth: 1)
                                )
                            
                            Text(String(stock.code.prefix(2)))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(stock.code)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                            
                            // Match badge
                            if matchScore > 0 {
                                Text("\(matchScore)%")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(matchColor)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(matchColor.opacity(0.15))
                                    .cornerRadius(6)
                            }
                        }
                        
                        Text(stock.name)
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Price & change
                VStack(alignment: .trailing, spacing: 4) {
                    Text(stock.formattedPrice)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: stock.isPositive ? "arrow.up" : "arrow.down")
                            .font(.system(size: 10, weight: .bold))
                        
                        Text(stock.formattedChangePercent)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(stock.changeColor)
                }
                
                // Favorite button
                Button(action: onFavoriteTap) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 16))
                        .foregroundColor(isFavorite ? AppColors.error : AppColors.textTertiary)
                        .scaleEffect(isFavorite ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isFavorite)
                }
                .padding(.leading, 12)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
    }
}

// MARK: - Supporting Types
enum FilterType: CaseIterable {
    case all
    case popular
    case gainers
    case favorites
    
    var displayName: String {
        switch self {
        case .all: return "Tümü"
        case .popular: return "Popüler"
        case .gainers: return "Yükselenler"
        case .favorites: return "Favoriler"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "📊"
        case .popular: return "🔥"
        case .gainers: return "📈"
        case .favorites: return "❤️"
        }
    }
}

// MARK: - Navigation Bar Extension
extension View {
    func navigationBarBackground(_ color: Color) -> some View {
        self.background(
            color
                .ignoresSafeArea(.container, edges: .top)
        )
    }
}

// MARK: - View Model
@MainActor
class HomeViewModel: ObservableObject {
    @Published var stocks: [UISymbol] = []
    @Published var filteredStocks: [UISymbol] = []
    @Published var topGainers: [UISymbol] = []
    @Published var topLosers: [UISymbol] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var searchText = "" {
        didSet {
            filterStocks()
        }
    }
    @Published var selectedFilter: FilterType = .all {
        didSet {
            filterStocks()
        }
    }
    
    private var favoriteStocks: Set<String> = []
    private var refreshTimer: Timer?
    
    init() {
        loadFavorites()
        startAutoRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    func loadData() async {
        isLoading = true
        showError = false
        errorMessage = ""
        
        do {
            // Simulate loading delay for better UX
            try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            
            guard let url = URL(string: "http://localhost:4000/api/v1/symbols?page=1&limit=1000&sort=code&order=asc") else {
                throw APIError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 30
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw APIError.serverError(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(HomeSymbolsAPIResponse.self, from: data)
            
            if apiResponse.success {
                self.stocks = apiResponse.data.map { UISymbol(from: $0) }
                
                // Add mock price data for demonstration
                addMockPriceData()
                updateTopMovers()
                filterStocks()
            } else {
                throw APIError.serverError(0)
            }
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        await loadData()
    }
    
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task { @MainActor in
                // Only refresh mock prices, not full data
                self.addMockPriceData()
                self.updateTopMovers()
                self.filterStocks()
            }
        }
    }
    
    private func addMockPriceData() {
        for i in 0..<stocks.count {
            let basePrice = Double.random(in: 50...500)
            let change = Double.random(in: -20...20)
            let changePercent = (change / basePrice) * 100
            
            stocks[i].price = basePrice
            stocks[i].change = change
            stocks[i].changePercent = changePercent
            stocks[i].volume = Int64.random(in: 100_000...50_000_000)
            stocks[i].high = basePrice + Double.random(in: 0...10)
            stocks[i].low = basePrice - Double.random(in: 0...10)
            stocks[i].open = basePrice + Double.random(in: -5...5)
            stocks[i].previousClose = basePrice - change
        }
    }
    
    private func filterStocks() {
        var filtered = stocks
        
        if !searchText.isEmpty {
            filtered = filtered.filter { stock in
                stock.code.localizedCaseInsensitiveContains(searchText) ||
                stock.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        switch selectedFilter {
        case .all:
            break
        case .popular:
            // Popular stocks: High volume ones
            filtered = filtered.sorted { $0.volume > $1.volume }.prefix(50).map { $0 }
        case .gainers:
            filtered = filtered.filter { $0.changePercent > 0 }.sorted { $0.changePercent > $1.changePercent }
        case .favorites:
            filtered = filtered.filter { favoriteStocks.contains($0.code) }
        }
        
        filteredStocks = Array(filtered)
    }
    
    private func updateTopMovers() {
        let activeStocks = stocks.filter { $0.price > 0 }
        topGainers = Array(activeStocks.filter { $0.changePercent > 0 }
                                      .sorted { $0.changePercent > $1.changePercent }
                                      .prefix(5))
        topLosers = Array(activeStocks.filter { $0.changePercent < 0 }
                                     .sorted { $0.changePercent < $1.changePercent }
                                     .prefix(5))
    }
    
    private func loadFavorites() {
        if let saved = UserDefaults.standard.stringArray(forKey: "favoriteStocks") {
            favoriteStocks = Set(saved)
        }
    }
    
    private func handleError(_ error: Error) {
        if let apiError = error as? APIError {
            switch apiError {
            case .invalidURL:
                errorMessage = "Geçersiz URL adresi"
            case .invalidResponse:
                errorMessage = "Sunucu yanıtı geçersiz"
            case .serverError(let code):
                errorMessage = "Sunucu hatası (Kod: \(code))"
            default:
                errorMessage = "Bilinmeyen hata oluştu"
            }
        } else if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                errorMessage = "İnternet bağlantısı yok"
            case .timedOut:
                errorMessage = "Bağlantı zaman aşımına uğradı"
            default:
                errorMessage = "Ağ bağlantısı hatası"
            }
        } else {
            errorMessage = "Veri yüklenirken hata oluştu"
        }
        showError = true
    }
}

// MARK: - Enhanced UISymbol Model
struct UISymbol {
    let code: String
    let name: String
    let exchange: String
    let logoPath: String
    var price: Double = 0
    var change: Double = 0
    var changePercent: Double = 0
    var volume: Int64 = 0
    var high: Double = 0
    var low: Double = 0
    var open: Double = 0
    var previousClose: Double = 0
    
    init(from apiSymbol: HomeAPISymbol) {
        self.code = apiSymbol.code
        self.name = apiSymbol.name
        self.exchange = apiSymbol.exchange
        self.logoPath = apiSymbol.logoPath
    }
    
    var isPositive: Bool { changePercent >= 0 }
    
    var changeColor: Color {
        isPositive ? AppColors.primary : AppColors.error
    }
    
    var formattedPrice: String {
        if price == 0 { return "N/A" }
        return "$\(String(format: "%.2f", price))"
    }
    
    var formattedChange: String {
        if change == 0 { return "0.00" }
        return "\(isPositive ? "+" : "")$\(String(format: "%.2f", abs(change)))"
    }
    
    var formattedChangePercent: String {
        if changePercent == 0 { return "0.00%" }
        return "\(isPositive ? "+" : "")\(String(format: "%.2f", changePercent))%"
    }
    
    var formattedVolume: String {
        if volume == 0 { return "N/A" }
        if volume >= 1_000_000 {
            return String(format: "%.1fM", Double(volume) / 1_000_000)
        } else if volume >= 1_000 {
            return String(format: "%.0fK", Double(volume) / 1_000)
        } else {
            return "\(volume)"
        }
    }
    
    var dayRange: String {
        if low == 0 || high == 0 { return "N/A" }
        return "$\(String(format: "%.2f", low)) - $\(String(format: "%.2f", high))"
    }
}

// MARK: - API Models
struct HomeAPISymbol: Codable {
    let code: String
    let name: String
    let exchange: String
    let logoPath: String
    
    enum CodingKeys: String, CodingKey {
        case code, name, exchange
        case logoPath = "logo_path"
    }
}

// MARK: - API Response Models
struct HomeSymbolsAPIResponse: Codable {
    let success: Bool
    let data: [HomeAPISymbol]
    let pagination: HomePaginationInfo
    let meta: HomeMetaInfo
}

struct HomePaginationInfo: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let pages: Int
}

struct HomeMetaInfo: Codable {
    let timestamp: Int64
}

// MARK: - Extension for Corner Radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HomeView(authVM: AuthViewModel())
        }
        .preferredColorScheme(.dark)
    }
}
