import SwiftUI
import Combine

struct HomeView: View {
    @ObservedObject var authVM: AuthViewModel
    @StateObject private var viewModel = HomeViewModel()
    @State private var searchText = ""
    @State private var selectedFilter: FilterType = .all
    @State private var favoriteStocks: Set<String> = []
    @State private var showingFavorites = false
    @State private var selectedStock: UISymbol?
    @State private var showingStockDetail = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Piyasalar")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.textPrimary)
                            
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                
                                Text("Canlı Fiyatlar")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .padding(.bottom, 4)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Button(action: { showingFavorites = true }) {
                                ZStack {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(AppColors.primary)
                                    
                                    if !favoriteStocks.isEmpty {
                                        Text("\(favoriteStocks.count)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(minWidth: 16, minHeight: 16)
                                            .background(AppColors.error)
                                            .clipShape(Circle())
                                            .offset(x: 12, y: -12)
                                    }
                                }
                                .frame(width: 44, height: 44)
                                .background(AppColors.cardBackground)
                                .clipShape(Circle())
                            }
                            
                            Button(action: {
                                Task { await viewModel.refreshData() }
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                                    .frame(width: 44, height: 44)
                                    .background(AppColors.cardBackground)
                                    .clipShape(Circle())
                                    .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                                    .animation(
                                        viewModel.isLoading ?
                                        .linear(duration: 1).repeatForever(autoreverses: false) :
                                        .default,
                                        value: viewModel.isLoading
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Search Bar
                            HStack(spacing: 12) {
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
                                .padding(.vertical, 14)
                                .background(AppColors.cardBackground)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)
                            
                            // Filter Chips
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(FilterType.allCases, id: \.self) { filter in
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedFilter = filter
                                            }
                                        }) {
                                            HStack(spacing: 8) {
                                                Text(filter.icon)
                                                    .font(.system(size: 14))
                                                
                                                Text(filter.displayName)
                                                    .font(.system(size: 14, weight: .semibold))
                                                
                                                Text("\(getFilterCount(for: filter))")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(selectedFilter == filter ? .black.opacity(0.7) : AppColors.textSecondary)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(
                                                        Capsule()
                                                            .fill(selectedFilter == filter ? .black.opacity(0.15) : AppColors.cardBackground)
                                                    )
                                            }
                                            .foregroundColor(selectedFilter == filter ? .black : AppColors.textPrimary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(
                                                Capsule()
                                                    .fill(selectedFilter == filter ? AppColors.primary : AppColors.cardBackground)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Market Overview - Sadece Market Stats
                            if selectedFilter == .all && searchText.isEmpty {
                                // Market Stats
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        MarketStatCard(
                                            title: "BIST 100",
                                            value: "8,432.12",
                                            change: "+2.34%",
                                            isPositive: true
                                        )
                                        
                                        MarketStatCard(
                                            title: "Dolar-TL",
                                            value: "32.45",
                                            change: "-0.12%",
                                            isPositive: false
                                        )
                                        
                                        MarketStatCard(
                                            title: "Altın (gr)",
                                            value: "2,145",
                                            change: "+1.87%",
                                            isPositive: true
                                        )
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            
                            // Stocks List
                            LazyVStack(spacing: 0) {
                                if viewModel.isLoading && viewModel.stocks.isEmpty {
                                    ForEach(0..<10, id: \.self) { _ in
                                        LoadingStockRow()
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 8)
                                    }
                                } else if viewModel.filteredStocks.isEmpty {
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
                                } else {
                                    ForEach(viewModel.filteredStocks, id: \.code) { stock in
                                        Button(action: {
                                            selectedStock = stock
                                            showingStockDetail = true
                                        }) {
                                            StockRow(
                                                stock: stock,
                                                isFavorite: favoriteStocks.contains(stock.code),
                                                onFavoriteToggle: {
                                                    toggleFavorite(stock.code)
                                                }
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                            .padding(.top, 20)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showingStockDetail) {
                if let stock = selectedStock {
                    SymbolDetailView(symbol: stock.code)
                }
            }
        }
        .sheet(isPresented: $showingFavorites) {
            FavoritesSheet(
                favoriteStocks: favoriteStocks,
                allStocks: viewModel.stocks,
                onRemoveFavorite: { stockCode in
                    toggleFavorite(stockCode)
                }
            )
        }
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
                    VStack {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text(viewModel.errorMessage)
                                .foregroundColor(.white)
                                .font(.subheadline)
                            Spacer()
                            Button("Tekrar Dene") {
                                Task {
                                    await viewModel.refreshData()
                                }
                            }
                            .foregroundColor(AppColors.primary)
                            .font(.subheadline)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        Spacer()
                    }
                    .transition(.move(edge: .top))
                }
            }
        )
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

// MARK: - Profil Uyumluluk Helper
func calculateMatchScore(for stock: UISymbol) -> Int {
    let stockCode = stock.code.lowercased()
    
    let predefinedScores: [String: Int] = [
        "aapl": 85,     // Apple - Yüksek büyüme
        "abbv": 72,     // AbbVie - Temettü odaklı
        "msft": 88,     // Microsoft - Teknoloji
        "tsla": 92,     // Tesla - Agresif büyüme
        "jnj": 68,      // Johnson & Johnson - Konservatif
        "ko": 65,       // Coca Cola - Konservatif
        "nvda": 95,     // NVIDIA - Yüksek büyüme
        "googl": 84,    // Google - Büyüme
        "amzn": 87,     // Amazon - Büyüme
        "bac": 58,      // Bank of America - Orta
        "pfe": 62,      // Pfizer - Konservatif
        "xom": 45,      // Exxon - Düşük uyumluluk
        "ge": 52,       // General Electric - Düşük
        "f": 48,        // Ford - Düşük
        "nke": 76,      // Nike - Orta-Yüksek
        "dis": 71,      // Disney - Orta
        "v": 82,        // Visa - Yüksek
        "ma": 81,       // Mastercard - Yüksek
        "wmt": 64,      // Walmart - Konservatif
        "hd": 73        // Home Depot - Orta-Yüksek
    ]
    
    if let predefinedScore = predefinedScores[stockCode] {
        return predefinedScore
    }
    
    let randomFactor = stock.code.hashValue % 100
    let baseScore = 40 + (randomFactor % 56)
    
    return baseScore
}

// MARK: - Profil Uyumluluk Badge Component
struct ProfileMatchBadge: View {
    let matchScore: Int
    
    private var badgeColor: Color {
        switch matchScore {
        case 0..<40:
            return Color(red: 239/255, green: 68/255, blue: 68/255) // Kırmızı
        case 40..<60:
            return Color(red: 245/255, green: 166/255, blue: 35/255) // Sarı/Turuncu
        default:
            return Color(red: 34/255, green: 197/255, blue: 94/255) // Yeşil
        }
    }
    
    private var badgeText: String {
        switch matchScore {
        case 0..<40:
            return "Düşük"
        case 40..<60:
            return "Orta"
        default:
            return "Yüksek"
        }
    }
    
    private var badgeIcon: String {
        switch matchScore {
        case 0..<40:
            return "arrow.down.circle.fill"
        case 40..<60:
            return "minus.circle.fill"
        default:
            return "arrow.up.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: badgeIcon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(badgeColor)
            
            Text(badgeText)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(badgeColor)
            
            Text("\(matchScore)%")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(badgeColor.opacity(0.8))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(badgeColor.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(badgeColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Stock Row Component
struct StockRow: View {
    let stock: UISymbol
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Stock Logo
            AsyncImage(url: URL(string: "http://192.168.1.210:4000\(stock.logoPath)")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [AppColors.primary, AppColors.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text(String(stock.code.prefix(2)))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 48, height: 48)
            .cornerRadius(12)
            
            // Stock Info
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(stock.code)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    // Profil Uyumluluk Badge'i
                    ProfileMatchBadge(matchScore: calculateMatchScore(for: stock))
                }
                
                Text(stock.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
                
                Text("Vol: \(stock.formattedVolume)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            // Price and Change Info
            VStack(alignment: .trailing, spacing: 6) {
                Text(stock.formattedPrice)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: 6) {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: stock.isPositive ? "triangle.fill" : "triangle.fill")
                                .font(.system(size: 8))
                                .rotationEffect(.degrees(stock.isPositive ? 0 : 180))
                                .foregroundColor(stock.changeColor)
                            
                            Text(stock.formattedChangePercent)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(stock.changeColor)
                        }
                        
                        Text(stock.formattedChange)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    // Favorite Button
                    Button(action: onFavoriteToggle) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundColor(isFavorite ? AppColors.error : AppColors.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(isFavorite ? AppColors.error.opacity(0.1) : AppColors.cardBackground)
                            )
                    }
                }
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

// MARK: - Loading Stock Row
struct LoadingStockRow: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Logo placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .frame(width: 48, height: 48)
                .opacity(isAnimating ? 0.3 : 0.7)
            
            // Info placeholder
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 60, height: 16)
                    .opacity(isAnimating ? 0.3 : 0.7)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 120, height: 12)
                    .opacity(isAnimating ? 0.3 : 0.7)
            }
            
            Spacer()
            
            // Price placeholder
            VStack(alignment: .trailing, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 80, height: 16)
                    .opacity(isAnimating ? 0.3 : 0.7)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 60, height: 12)
                    .opacity(isAnimating ? 0.3 : 0.7)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cardBackground)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
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
