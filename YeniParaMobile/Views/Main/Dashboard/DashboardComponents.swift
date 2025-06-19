import SwiftUI

// MARK: - Featured Stocks Section
struct FeaturedStocksSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Öne Çıkan Hisseler")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.featuredStocks) { stock in
                        FeaturedStockCard(stock: stock)
                    }
                }
                .padding(.horizontal, 20)
            }
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
                .padding(.horizontal, 20)
            
            HStack(spacing: 12) {
                QuickActionButton(icon: "magnifyingglass", title: "Ara", color: AppColors.primary)
                QuickActionButton(icon: "heart.fill", title: "Favoriler", color: AppColors.error)
                QuickActionButton(icon: "bell.fill", title: "Uyarılar", color: Color.orange)
                QuickActionButton(icon: "chart.pie.fill", title: "Portföy", color: Color.purple)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Market News Section
struct MarketNewsSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Piyasa Haberleri")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Button("Tümü") {
                    // Navigate to all news
                }
                .font(.subheadline)
                .foregroundColor(AppColors.primary)
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(viewModel.news) { item in
                    NewsCard(news: item)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Helper Components
struct FeaturedStockCard: View {
    let stock: Asset
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(stock.symbol)
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            Text(stock.formattedPrice)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            HStack {
                Text(stock.formattedChangePercent)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(stock.changeColor)
            }
        }
        .frame(width: 140)
        .padding(16)
        .background(AppColors.cardBackground)
        .cornerRadius(12)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(AppColors.cardBackground)
        .cornerRadius(12)
    }
}

struct NewsCard: View {
    let news: NewsItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(news.title)
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(2)
            
            Text(news.summary)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(2)
            
            Text(news.time)
                .font(.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppColors.cardBackground)
        .cornerRadius(12)
    }
}
