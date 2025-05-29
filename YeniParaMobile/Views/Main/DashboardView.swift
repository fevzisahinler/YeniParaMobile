import SwiftUI

struct DashboardView: View {
    @ObservedObject var authVM: AuthViewModel
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    DashboardHeaderView()
                    
                    // Market Overview
                    MarketOverviewSection(authVM: authVM)
                    
                    // Featured Stocks
                    FeaturedStocksSection()
                    
                    // Quick Actions
                    QuickActionsSection()
                    
                    // Market News
                    MarketNewsSection()
                }
                .padding(.vertical, 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadDashboardData()
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

// MARK: - Market Overview Section
struct MarketOverviewSection: View {
    @ObservedObject var authVM: AuthViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Piyasa Durumu")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                NavigationLink(destination: HomeView(authVM: authVM)) {
                    Text("Tümünü Gör")
                        .font(.subheadline)
                        .foregroundColor(AppColors.primary)
                }
            }
            .padding(.horizontal, AppConstants.screenPadding)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    DashboardMarketCard(title: "S&P 500", value: "4,567.23", change: "+2.34%", isPositive: true)
                    DashboardMarketCard(title: "NASDAQ", value: "14,432.12", change: "-0.89%", isPositive: false)
                    DashboardMarketCard(title: "Dow Jones", value: "34,876.45", change: "+1.12%", isPositive: true)
                    DashboardMarketCard(title: "VIX", value: "18.45", change: "-3.21%", isPositive: false)
                }
                .padding(.horizontal, AppConstants.screenPadding)
            }
        }
    }
}

// MARK: - Featured Stocks Section
struct FeaturedStocksSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Günün Öne Çıkanları")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text("SP100")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.cardBackground)
                    .cornerRadius(8)
            }
            .padding(.horizontal, AppConstants.screenPadding)
            
            VStack(spacing: 8) {
                FeaturedStockRow(symbol: "AAPL", company: "Apple Inc.", price: "$175.23", change: "+2.45%", isPositive: true)
                FeaturedStockRow(symbol: "TSLA", company: "Tesla Inc.", price: "$245.67", change: "-1.23%", isPositive: false)
                FeaturedStockRow(symbol: "MSFT", company: "Microsoft Corp.", price: "$348.91", change: "+3.12%", isPositive: true)
                FeaturedStockRow(symbol: "GOOGL", company: "Alphabet Inc.", price: "$142.56", change: "+1.87%", isPositive: true)
            }
            .padding(.horizontal, AppConstants.screenPadding)
        }
    }
}

// MARK: - Quick Actions Section
struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hızlı İşlemler")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, AppConstants.screenPadding)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                QuickActionCard(icon: "chart.line.uptrend.xyaxis", title: "Hisseler", subtitle: "SP100 hisselerini incele")
                QuickActionCard(icon: "magnifyingglass", title: "Arama", subtitle: "Hisse senedi ara")
                QuickActionCard(icon: "star", title: "Favoriler", subtitle: "İzleme listesi")
                QuickActionCard(icon: "bell", title: "Bildirimler", subtitle: "Fiyat uyarıları")
            }
            .padding(.horizontal, AppConstants.screenPadding)
        }
    }
}

// MARK: - Market News Section
struct MarketNewsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Piyasa Haberleri")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Button(action: {}) {
                    Text("Tümü")
                        .font(.subheadline)
                        .foregroundColor(AppColors.primary)
                }
            }
            .padding(.horizontal, AppConstants.screenPadding)
            
            VStack(spacing: 12) {
                NewsCard(
                    title: "Fed Faiz Kararı Açıklandı",
                    summary: "Federal Reserve faiz oranlarını sabit tutma kararı aldı",
                    time: "2 saat önce"
                )
                NewsCard(
                    title: "Apple'dan Yeni iPhone Açıklaması",
                    summary: "Apple'ın yeni ürün lansmanı hisse fiyatlarını etkiledi",
                    time: "4 saat önce"
                )
                NewsCard(
                    title: "Teknoloji Hisseleri Yükselişte",
                    summary: "NASDAQ'ta teknoloji sektörü güçlü performans sergiliyor",
                    time: "6 saat önce"
                )
            }
            .padding(.horizontal, AppConstants.screenPadding)
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
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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

struct FeaturedStockRow: View {
    let symbol: String
    let company: String
    let price: String
    let change: String
    let isPositive: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(symbol.prefix(2)))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(symbol)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(company)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(price)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(change)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isPositive ? AppColors.primary : AppColors.error)
            }
        }
        .padding(.vertical, 8)
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

struct NewsCard: View {
    let title: String
    let summary: String
    let time: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(2)
            
            Text(summary)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(2)
            
            Text(time)
                .font(.caption)
                .foregroundColor(AppColors.textTertiary)
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

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DashboardView(authVM: AuthViewModel())
        }
        .preferredColorScheme(.dark)
    }
}
