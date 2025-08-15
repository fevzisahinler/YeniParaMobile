import SwiftUI

struct DashboardView: View {
    @ObservedObject var authVM: AuthViewModel
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    DashboardHeaderView()
                    
                    // Macro Economic Data Section - NEW
                    if let macroData = viewModel.macroSummary {
                        MacroSummarySection(
                            macroData: macroData,
                            onNavigateToDetail: { dataType in
                                navigationManager.navigateToMacroDetail(dataType)
                            }
                        )
                    } else if viewModel.isMacroLoading {
                        MacroSummaryLoadingView()
                    } else if let error = viewModel.macroError {
                        MacroSummaryErrorView(
                            error: error,
                            onRetry: {
                                Task {
                                    await viewModel.loadMacroData()
                                }
                            }
                        )
                    }
                    
                    // Top Movers with Toggle
                    TopMoversWithToggle(
                        topGainers: viewModel.topGainers,
                        topLosers: viewModel.topLosers,
                        navigationManager: navigationManager,
                        authToken: TokenManager.shared.getAccessToken(),
                        marketInfo: viewModel.marketInfo
                    )
                    
                    // News Section
                    MarketNewsSection(
                        newsItems: viewModel.newsItems,
                        isLoading: viewModel.isNewsLoading,
                        hasMoreNews: viewModel.hasMoreNews,
                        onLoadMore: {
                            Task {
                                await viewModel.loadMoreNews()
                            }
                        },
                        onNewsItemTap: { news in
                            navigationManager.selectedNews = news
                            navigationManager.showNewsDetail = true
                        }
                    )
                    
                    // Bottom padding
                    Color.clear.frame(height: 40)
                }
                .padding(.vertical, 20)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $navigationManager.showMacroDetail) {
            if let macroType = navigationManager.selectedMacroType {
                MacroDetailView(dataType: macroType)
            }
        }
        .sheet(isPresented: $navigationManager.showStockDetail) {
            if let symbol = navigationManager.selectedStock {
                SymbolDetailView(symbol: symbol)
                    .environmentObject(navigationManager)
            }
        }
        .sheet(isPresented: $navigationManager.showNewsDetail) {
            if let news = navigationManager.selectedNews {
                NewsDetailView(news: news)
                    .environmentObject(navigationManager)
            }
        }
        .onAppear {
            viewModel.loadDashboardData()
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
    }
}

// MARK: - Dashboard Header
struct DashboardHeaderView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hoş geldiniz!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Piyasaya genel bakış")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "bell")
                    .font(.title3)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(AppColors.cardBackground)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, AppConstants.screenPadding)
    }
}



// MARK: - Top Movers with Toggle
struct TopMoversWithToggle: View {
    let topGainers: [UISymbol]
    let topLosers: [UISymbol]
    @ObservedObject var navigationManager: NavigationManager
    let authToken: String?
    let marketInfo: MarketInfo?
    
    @State private var showingGainers = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Toggle
            VStack(spacing: 12) {
                HStack {
                    Text("Günün Öne Çıkanları")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    // Market Status Indicator
                    if let marketInfo = marketInfo {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(marketStatusColor(marketInfo.status))
                                .frame(width: 8, height: 8)
                            Text(marketStatusText(marketInfo.status))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(AppColors.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(marketStatusColor(marketInfo.status).opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, AppConstants.screenPadding)
                
                // Toggle Buttons
                HStack(spacing: 0) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            showingGainers = true
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 14))
                            Text("En Çok Artanlar")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(showingGainers ? .white : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(showingGainers ? AppColors.success : Color.clear)
                        )
                    }
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            showingGainers = false
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 14))
                            Text("En Çok Azalanlar")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(!showingGainers ? .white : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(!showingGainers ? AppColors.error : Color.clear)
                        )
                    }
                }
                .padding(3)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.cardBorder, lineWidth: 1)
                        )
                )
                .padding(.horizontal, AppConstants.screenPadding)
            }
            
            // Stock List
            VStack(spacing: 8) {
                let stocks = showingGainers ? topGainers : topLosers
                
                if stocks.isEmpty {
                    Text("Veri yükleniyor...")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    ForEach(stocks.prefix(5), id: \.code) { stock in
                        StockRowCard(
                            stock: stock,
                            authToken: authToken,
                            onTap: {
                                navigationManager.navigateToStock(stock.code)
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, AppConstants.screenPadding)
        }
    }
    
    private func marketStatusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "open":
            return AppColors.success
        case "closed":
            return AppColors.error
        case "pre-market":
            return Color.orange
        case "after-hours":
            return Color.purple
        default:
            return AppColors.textSecondary
        }
    }
    
    private func marketStatusText(_ status: String) -> String {
        switch status.lowercased() {
        case "open":
            return "Piyasa Açık"
        case "closed":
            return "Piyasa Kapalı"
        case "pre-market":
            return "Piyasa Öncesi"
        case "after-hours":
            return "Piyasa Sonrası"
        default:
            return status
        }
    }
}


// MARK: - Stock Row Card
struct StockRowCard: View {
    let stock: UISymbol
    let authToken: String?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Logo with bearer token
                StockLogoView(symbol: stock.code, logoPath: stock.logoPath, size: 36, authToken: authToken)
                    .clipShape(Circle())
                
                // Symbol & Name
                VStack(alignment: .leading, spacing: 2) {
                    Text(stock.code)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(stock.name)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Price & Change
                VStack(alignment: .trailing, spacing: 2) {
                    Text(stock.formattedPrice)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: 3) {
                        Image(systemName: stock.isPositive ? "arrow.up" : "arrow.down")
                            .font(.system(size: 9, weight: .bold))
                        Text(stock.formattedChangePercent)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(stock.changeColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                    .fill(AppColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                            .stroke(AppColors.cardBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}




// MARK: - Market News Section
struct MarketNewsSection: View {
    let newsItems: [NewsItem]
    let isLoading: Bool
    let hasMoreNews: Bool
    let onLoadMore: () -> Void
    let onNewsItemTap: (NewsItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("📰 Piyasa Haberleri")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                if !newsItems.isEmpty {
                    Text("\(newsItems.count) haber")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.horizontal, AppConstants.screenPadding)
            
            if isLoading && newsItems.isEmpty {
                // Loading state
                VStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        NewsLoadingCard()
                    }
                }
                .padding(.horizontal, AppConstants.screenPadding)
            } else if newsItems.isEmpty {
                // Empty state
                Text("Henüz haber bulunmuyor")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                // News list
                VStack(spacing: 12) {
                    ForEach(newsItems) { news in
                        MarketNewsCard(
                            news: news,
                            onTap: {
                                onNewsItemTap(news)
                            }
                        )
                    }
                    
                    // Load more button
                    if hasMoreNews {
                        Button(action: onLoadMore) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Yükleniyor...")
                                        .font(.system(size: 13, weight: .medium))
                                } else {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.system(size: 16))
                                    Text("Daha fazla haber yükle")
                                        .font(.system(size: 13, weight: .medium))
                                }
                            }
                            .foregroundColor(AppColors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(AppColors.primary.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(AppColors.primary.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        .disabled(isLoading)
                    } else if !newsItems.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.success)
                            Text("Tüm haberler yüklendi")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, AppConstants.screenPadding)
            }
        }
    }
}

// MARK: - Market News Card
struct MarketNewsCard: View {
    let news: NewsItem
    let onTap: () -> Void
    
    private func getImportanceText(_ level: Int) -> String {
        switch level {
        case 5:
            return "Çok Önemli"
        case 4:
            return "Önemli"
        case 3:
            return "Normal"
        default:
            return "Düşük"
        }
    }
    
    private func getImportanceColor(_ level: Int) -> Color {
        switch level {
        case 5:
            return Color.red
        case 4:
            return Color.orange
        case 3:
            return Color.blue
        default:
            return Color.gray
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                // Header with symbol and importance
                HStack(spacing: 8) {
                    // Symbol badge
                    HStack(spacing: 4) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 10, weight: .semibold))
                        Text(news.symbolCode)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(AppColors.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppColors.primary.opacity(0.15))
                    )
                    
                    // Importance
                    Text(getImportanceText(news.importanceLevel))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(getImportanceColor(news.importanceLevel))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(getImportanceColor(news.importanceLevel).opacity(0.15))
                        )
                    
                    // Sentiment
                    Text(news.sentimentEmoji)
                        .font(.system(size: 12))
                    
                    Spacer()
                    
                    // Time
                    Text(news.formattedDate)
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.textTertiary)
                }
                
                // Headline
                Text(news.headline)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                // Summary (if exists)
                if !news.summary.isEmpty && news.summary != " " {
                    Text(news.summary)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                // Footer
                HStack {
                    // Author
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 10))
                        Text(news.author)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(AppColors.textTertiary)
                    
                    Spacer()
                    
                    // External link button
                    Button(action: {
                        if let url = URL(string: news.url) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text("Habere Git")
                                .font(.system(size: 11, weight: .medium))
                            Image(systemName: "arrow.up.forward.square")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(AppColors.primary)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                    .fill(AppColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                            .stroke(AppColors.cardBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - News Loading Card
struct NewsLoadingCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 60, height: 20)
                    .shimmer(isAnimating: isAnimating)
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 50, height: 12)
                    .shimmer(isAnimating: isAnimating)
            }
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.1))
                .frame(height: 16)
                .shimmer(isAnimating: isAnimating)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.1))
                .frame(height: 12)
                .shimmer(isAnimating: isAnimating)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .fill(AppColors.cardBackground)
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Community View Supporting Sections
struct PopularTopicsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Popüler Konular")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, AppConstants.screenPadding)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    TopicTag(title: "Fed Kararları", count: "124")
                    TopicTag(title: "Tech Hisseleri", count: "89")
                    TopicTag(title: "Enflasyon", count: "67")
                    TopicTag(title: "Kripto", count: "45")
                    TopicTag(title: "Altın", count: "34")
                }
                .padding(.horizontal, AppConstants.screenPadding)
            }
        }
    }
}

struct ComingSoonSection: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.sequence")
                .font(.system(size: 48))
                .foregroundColor(AppColors.primary)
            
            VStack(spacing: 8) {
                Text("Topluluk Özellikleri")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Yakında burada diğer yatırımcılarla:")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                FeatureItem(icon: "message", text: "Mesajlaşma ve sohbet")
                FeatureItem(icon: "chart.bar.doc.horizontal", text: "Analiz paylaşımı")
                FeatureItem(icon: "lightbulb", text: "Yatırım tavsiyeleri")
                FeatureItem(icon: "trophy", text: "Başarı rozetleri")
            }
            .padding(.horizontal, 40)
        }
        .padding(.vertical, 30)
    }
}

// MARK: - Profile View Supporting Sections
struct AccountInfoCard: View {
    @ObservedObject var authVM: AuthViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Investor Profile Section
            if let profile = authVM.investorProfile {
                HStack {
                    Text("Yatırımcı Profili")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Text(profile.icon ?? "📊")
                        .font(.title2)
                }
                
                VStack(spacing: 12) {
                    InfoRowDashboard(title: "Tip", value: profile.name)
                    if let nickname = profile.nickname {
                        InfoRowDashboard(title: "Lakap", value: nickname)
                    }
                    InfoRowDashboard(title: "Risk Toleransı", value: getRiskToleranceText(profile.riskTolerance))
                    InfoRowDashboard(title: "Yatırım Ufku", value: getInvestmentHorizonText(profile.investmentHorizon))
                }
                
                // Portfolio Allocation
                VStack(spacing: 12) {
                    HStack {
                        Text("Portföy Dağılımı")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        AllocationBadge(
                            title: "Hisse",
                            percentage: profile.stockAllocationPercentage,
                            color: AppColors.primary
                        )
                        AllocationBadge(
                            title: "Tahvil",
                            percentage: profile.bondAllocationPercentage,
                            color: Color(red: 52/255, green: 152/255, blue: 219/255)
                        )
                        AllocationBadge(
                            title: "Nakit",
                            percentage: profile.cashAllocationPercentage,
                            color: Color(red: 155/255, green: 89/255, blue: 182/255)
                        )
                    }
                }
                .padding(.top, 8)
                
                Divider()
                    .background(AppColors.cardBorder)
                    .padding(.vertical, 8)
            }
            
            Text("Hesap Bilgileri")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: 12) {
                InfoRowDashboard(title: "Üyelik Türü", value: "Ücretsiz")
                InfoRowDashboard(title: "Kayıt Tarihi", value: "Ocak 2024")
                InfoRowDashboard(title: "Son Giriş", value: "Bugün")
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
    
    private func getRiskToleranceText(_ riskTolerance: String) -> String {
        switch riskTolerance.uppercased() {
        case "LOW": return "Düşük"
        case "MEDIUM": return "Orta"
        case "HIGH": return "Yüksek"
        default: return riskTolerance
        }
    }
    
    private func getInvestmentHorizonText(_ horizon: String) -> String {
        switch horizon.uppercased() {
        case "SHORT_TERM": return "Kısa Vade"
        case "MEDIUM_TERM": return "Orta Vade"
        case "LONG_TERM": return "Uzun Vade"
        default: return horizon
        }
    }
}

// MARK: - Small Components
struct DashboardMarketCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            Text(change)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isPositive ? AppColors.primary : AppColors.error)
        }
        .padding(AppConstants.cardPadding)
        .frame(width: 120)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )
        )
    }
}


struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppColors.primary)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(AppConstants.cardPadding)
        .frame(height: 100)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )
        )
    }
}


struct TopicTag: View {
    let title: String
    let count: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textPrimary)
            
            Text(count)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AppColors.cardBackground)
                .cornerRadius(8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppColors.cardBackground)
        .cornerRadius(20)
    }
}

struct FeatureItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppColors.primary)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

struct InfoRowDashboard: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
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

struct ProfileMenuItem: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppColors.primary)
                .frame(width: 24)
            
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

// MARK: - Symbol Detail View Supporting Components
struct StatItem: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
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
    }
}

struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Allocation Badge
struct AllocationBadge: View {
    let title: String
    let percentage: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("%\(percentage)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DashboardView(authVM: AuthViewModel())
        }
        .preferredColorScheme(.dark)
    }
}
