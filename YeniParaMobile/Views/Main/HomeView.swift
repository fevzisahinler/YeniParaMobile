import SwiftUI

struct HomeView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var assets: [Asset] = []
    @State private var filteredAssets: [Asset] = []
    @State private var isLoading = false
    @State private var loadingError: String?
    @State private var searchText = ""
    @State private var selectedSort: SortType = .marketCap
    @State private var isAscending = false
    @State private var refreshID = UUID()

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Header
                topHeader
                
                // Market Stats Cards
                marketStatsCards
                
                // Search and Filter Bar
                searchFilterBar
                
                // Assets List
                if isLoading {
                    LoadingView(message: "Hisse verileri yükleniyor...")
                } else if let error = loadingError {
                    ErrorView(message: error) {
                        Task { await refreshData() }
                    }
                } else {
                    assetsList
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear(perform: loadMarketData)
        .refreshable {
            await refreshData()
        }
        .onChange(of: searchText) { _ in
            filterAssets()
        }
        .onChange(of: selectedSort) { _ in
            sortAssets()
        }
        .onChange(of: isAscending) { _ in
            sortAssets()
        }
    }

    // MARK: – Top Header
    private var topHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hisseler")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("SP100 hisseleri - Anlık veriler")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Menu {
                    ForEach(SortType.allCases, id: \.rawValue) { sortType in
                        Button(action: {
                            if selectedSort == sortType {
                                isAscending.toggle()
                            } else {
                                selectedSort = sortType
                                isAscending = false
                            }
                        }) {
                            HStack {
                                Text(sortType.rawValue)
                                if selectedSort == sortType {
                                    Image(systemName: isAscending ? "arrow.up" : "arrow.down")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.title3)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(AppColors.cardBackground)
                        .clipShape(Circle())
                }
                
                Button(action: { Task { await refreshData() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(AppColors.cardBackground)
                        .clipShape(Circle())
                        .rotationEffect(.degrees(isLoading ? 360 : 0))
                        .animation(isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
                }
            }
        }
        .padding(.horizontal, AppConstants.screenPadding)
        .padding(.top, 8)
    }

    // MARK: – Market Stats Cards
    private var marketStatsCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                MarketStatCard(
                    title: "S&P 500",
                    value: "4,567.23",
                    change: "+2.34%",
                    isPositive: true
                )
                
                MarketStatCard(
                    title: "NASDAQ",
                    value: "14,432.12",
                    change: "-0.89%",
                    isPositive: false
                )
                
                MarketStatCard(
                    title: "Dow Jones",
                    value: "34,876.45",
                    change: "+1.12%",
                    isPositive: true
                )
                
                MarketStatCard(
                    title: "SP100 Hisseleri",
                    value: "\(assets.count)",
                    change: "",
                    isPositive: true
                )
            }
            .padding(.horizontal, AppConstants.screenPadding)
        }
        .padding(.vertical, 16)
    }

    // MARK: – Search and Filter Bar
    private var searchFilterBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.textSecondary)
                
                TextField("Hisse ara... (AAPL, MSFT, vb.)", text: $searchText)
                    .foregroundColor(AppColors.textPrimary)
                    .font(.body)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.cardBackground)
            .cornerRadius(AppConstants.cornerRadius)
        }
        .padding(.horizontal, AppConstants.screenPadding)
    }

    // MARK: – Assets List
    private var assetsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Header
                HStack {
                    Text("Hisse")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("Fiyat")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 80, alignment: .trailing)
                    
                    Text("Değişim")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.horizontal, AppConstants.screenPadding)
                .padding(.vertical, 8)
                .background(AppColors.cardBackground)
                
                ForEach(filteredAssets) { asset in
                    NavigationLink(destination: SymbolDetailView(symbol: asset.symbol)) {
                        AssetRowView(asset: asset)
                            .padding(.horizontal, AppConstants.screenPadding)
                            .padding(.vertical, 12)
                            .background(Color.clear)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider()
                        .background(AppColors.cardBorder)
                        .padding(.horizontal, AppConstants.screenPadding)
                }
            }
        }
        .id(refreshID)
    }

    // MARK: – Data Loading Functions
    private func loadMarketData() {
        Task { await refreshData() }
    }

    private func refreshData() async {
        await MainActor.run { isLoading = true; loadingError = nil }
        
        // Simulated data loading
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let sampleAssets = [
            Asset(symbol: "AAPL", companyName: "Apple Inc.", price: 175.23, change: 4.12, changePercent: 2.45, volume: "45.2M", marketCap: "2.8T", high24h: 178.45, low24h: 172.10),
            Asset(symbol: "MSFT", companyName: "Microsoft Corp.", price: 348.91, change: 10.55, changePercent: 3.12, volume: "28.7M", marketCap: "2.6T", high24h: 352.30, low24h: 345.20),
            Asset(symbol: "GOOGL", companyName: "Alphabet Inc.", price: 142.56, change: 2.61, changePercent: 1.87, volume: "22.4M", marketCap: "1.8T", high24h: 145.20, low24h: 140.15),
            Asset(symbol: "TSLA", companyName: "Tesla Inc.", price: 245.67, change: -3.08, changePercent: -1.23, volume: "32.1M", marketCap: "780B", high24h: 250.12, low24h: 242.50),
            Asset(symbol: "AMZN", companyName: "Amazon.com Inc.", price: 128.45, change: 1.82, changePercent: 1.44, volume: "35.6M", marketCap: "1.3T", high24h: 130.75, low24h: 126.80)
        ]

        await MainActor.run {
            self.assets = sampleAssets
            self.filterAssets()
            self.sortAssets()
            self.refreshID = UUID()
            self.isLoading = false
        }
    }

    private func filterAssets() {
        if searchText.isEmpty {
            filteredAssets = assets
        } else {
            filteredAssets = assets.filter { asset in
                asset.symbol.lowercased().contains(searchText.lowercased()) ||
                asset.companyName.lowercased().contains(searchText.lowercased())
            }
        }
    }

    private func sortAssets() {
        filteredAssets.sort { asset1, asset2 in
            let result: Bool
            switch selectedSort {
            case .name:
                result = asset1.symbol < asset2.symbol
            case .price:
                result = asset1.price < asset2.price
            case .change:
                result = asset1.changePercent < asset2.changePercent
            case .volume:
                result = asset1.volume < asset2.volume
            case .marketCap:
                result = asset1.marketCap < asset2.marketCap
            }
            return isAscending ? result : !result
        }
    }
}

enum SortType: String, CaseIterable {
    case name = "İsim"
    case price = "Fiyat"
    case change = "Değişim"
    case volume = "Hacim"
    case marketCap = "Piyasa Değeri"
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView(authVM: AuthViewModel())
        }
        .preferredColorScheme(.dark)
    }
}
