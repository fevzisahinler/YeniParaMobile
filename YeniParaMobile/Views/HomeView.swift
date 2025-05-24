import SwiftUI

// MARK: – Models from your API

struct SymbolsResponse: Decodable {
    let data: [String]
    let success: Bool
}

struct HistoricalResponse: Decodable {
    let data: [CandleAPIModel]
}

struct CandleAPIModel: Decodable {
    let timestamp: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
}

// MARK: – Asset model for the list

struct Asset: Identifiable {
    let id = UUID()
    let symbol: String
    let companyName: String
    let price: Double
    let change: Double
    let changePercent: Double
    let volume: String
    let marketCap: String
    let high24h: Double
    let low24h: Double
}

enum SortType: String, CaseIterable {
    case name = "İsim"
    case price = "Fiyat"
    case change = "Değişim"
    case volume = "Hacim"
    case marketCap = "Piyasa Değeri"
}

// MARK: – HomeView

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
            // Background
            Color(red: 28/255, green: 29/255, blue: 36/255)
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
                    loadingView
                } else if let error = loadingError {
                    errorView(error)
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
                Text("SP100 Hisseleri")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Anlık fiyatlar ve veriler")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
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
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Button(action: { Task { await refreshData() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                        .rotationEffect(.degrees(isLoading ? 360 : 0))
                        .animation(isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
                }
            }
        }
        .padding(.horizontal, 20)
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
                    title: "Toplam Hisse",
                    value: "\(assets.count)",
                    change: "",
                    isPositive: true
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
    }

    // MARK: – Search and Filter Bar
    private var searchFilterBar: some View {
        HStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.6))
                
                TextField("Hisse ara... (AAPL, MSFT, vb.)", text: $searchText)
                    .foregroundColor(.white)
                    .font(.body)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
    }

    // MARK: – Assets List
    private var assetsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Header
                HStack {
                    Text("Hisse")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("Fiyat")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 80, alignment: .trailing)
                    
                    Text("Değişim")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.05))
                
                ForEach(filteredAssets) { asset in
                    NavigationLink(destination: SymbolDetailView(symbol: asset.symbol)) {
                        EnhancedAssetRowView(asset: asset)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.clear)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.horizontal, 20)
                }
            }
        }
        .id(refreshID)
    }

    // MARK: – Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 143/255, green: 217/255, blue: 83/255)))
                .scaleEffect(1.2)
            
            Text("Hisse verileri yükleniyor...")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: – Error View
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Bir hata oluştu")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Tekrar Dene") {
                Task { await refreshData() }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color(red: 143/255, green: 217/255, blue: 83/255))
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: – Data Loading Functions
    private func loadMarketData() {
        Task { await refreshData() }
    }

    private func refreshData() async {
        do {
            await MainActor.run { isLoading = true; loadingError = nil }
            
            // 1) Fetch symbol list
            let symbolsURL = URL(string: "http://localhost:4000/symbols")!
            let (symbolsData, _) = try await URLSession.shared.data(from: symbolsURL)
            let symbolsResp = try JSONDecoder().decode(SymbolsResponse.self, from: symbolsData)

            var tempAssets: [Asset] = []

            // 2) For each symbol, fetch the last 2 candles
            for raw in symbolsResp.data {
                let trimmed = raw.replacingOccurrences(of: ".US", with: "")

                var comps = URLComponents(string: "http://localhost:4000/candles/1d")!
                comps.queryItems = [
                    .init(name: "symbol", value: raw),
                    .init(name: "limit", value: "2")
                ]
                
                guard let candlesURL = comps.url else { continue }
                
                do {
                    let (candlesData, _) = try await URLSession.shared.data(from: candlesURL)
                    let histResp = try JSONDecoder().decode(HistoricalResponse.self, from: candlesData)
                    
                    let sorted = histResp.data.sorted { $0.timestamp > $1.timestamp }
                    guard sorted.count >= 2 else { continue }
                    
                    let latest = sorted[0]
                    let previous = sorted[1]
                    
                    let price = latest.close
                    let changeAmount = latest.close - previous.close
                    let changePercent = (changeAmount / previous.close) * 100
                    
                    // Company names for SP100 stocks
                    let companyName = getCompanyName(for: trimmed)
                    
                    // Generate volume and market cap
                    let volume = String(format: "%.1fM", latest.volume / 1_000_000)
                    let marketCap = String(format: "%.1fB", Double.random(in: 1...500))
                    
                    tempAssets.append(Asset(
                        symbol: trimmed,
                        companyName: companyName,
                        price: price,
                        change: changeAmount,
                        changePercent: changePercent,
                        volume: volume,
                        marketCap: marketCap,
                        high24h: latest.high,
                        low24h: latest.low
                    ))
                } catch {
                    print("Error loading data for \(trimmed): \(error)")
                    continue
                }
            }

            await MainActor.run {
                self.assets = tempAssets
                self.filterAssets()
                self.sortAssets()
                self.refreshID = UUID()
            }
        } catch {
            await MainActor.run {
                self.loadingError = "Hisse verileri yüklenirken hata oluştu: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run { isLoading = false }
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
    
    // MARK: - Helper function for company names
    private func getCompanyName(for symbol: String) -> String {
        let companyNames: [String: String] = [
            "AAPL": "Apple Inc.",
            "ABBV": "AbbVie Inc.",
            "ABT": "Abbott Laboratories",
            "ACN": "Accenture Plc",
            "ADBE": "Adobe Inc.",
            "AIG": "American International Group",
            "ALL": "Allstate Corp.",
            "AMGN": "Amgen Inc.",
            "AMZN": "Amazon.com Inc.",
            "APA": "APA Corp.",
            "AXP": "American Express Co.",
            "BA": "Boeing Co.",
            "BAC": "Bank of America Corp.",
            "BIIB": "Biogen Inc.",
            "BK": "Bank of New York Mellon",
            "BLK": "BlackRock Inc.",
            "BMY": "Bristol Myers Squibb",
            "C": "Citigroup Inc.",
            "CAT": "Caterpillar Inc.",
            "CHD": "Church & Dwight Co.",
            "CI": "Cigna Group",
            "CL": "Colgate-Palmolive Co.",
            "CMCSA": "Comcast Corp.",
            "COF": "Capital One Financial",
            "COP": "ConocoPhillips",
            "COST": "Costco Wholesale Corp.",
            "CRM": "Salesforce Inc.",
            "CSCO": "Cisco Systems Inc.",
            "CVS": "CVS Health Corp.",
            "CVX": "Chevron Corp.",
            "DHR": "Danaher Corp.",
            "DIS": "Walt Disney Co.",
            "DOW": "Dow Inc.",
            "DUK": "Duke Energy Corp.",
            "EMR": "Emerson Electric Co.",
            "EXC": "Exelon Corp.",
            "F": "Ford Motor Co.",
            "FB": "Meta Platforms Inc.",
            "FDX": "FedEx Corp.",
            "FOXA": "Fox Corp.",
            "GD": "General Dynamics Corp.",
            "GE": "General Electric Co.",
            "GILD": "Gilead Sciences Inc.",
            "GM": "General Motors Co.",
            "GOOG": "Alphabet Inc.",
            "GOOGL": "Alphabet Inc.",
            "GS": "Goldman Sachs Group",
            "HD": "Home Depot Inc.",
            "HON": "Honeywell International",
            "IBM": "International Business Machines",
            "ICE": "Intercontinental Exchange",
            "INTC": "Intel Corp.",
            "JNJ": "Johnson & Johnson",
            "JPM": "JPMorgan Chase & Co.",
            "KHC": "Kraft Heinz Co.",
            "KMI": "Kinder Morgan Inc.",
            "KO": "Coca-Cola Co.",
            "LLY": "Eli Lilly and Co.",
            "LMT": "Lockheed Martin Corp.",
            "LOW": "Lowe's Companies Inc.",
            "LRCX": "Lam Research Corp.",
            "MA": "Mastercard Inc.",
            "MCD": "McDonald's Corp.",
            "MDT": "Medtronic Plc",
            "MET": "MetLife Inc.",
            "MMM": "3M Co.",
            "MO": "Altria Group Inc.",
            "MRK": "Merck & Co Inc.",
            "MS": "Morgan Stanley",
            "NKE": "Nike Inc.",
            "ORCL": "Oracle Corp.",
            "OXY": "Occidental Petroleum",
            "PEP": "PepsiCo Inc.",
            "PFE": "Pfizer Inc.",
            "PG": "Procter & Gamble Co.",
            "PM": "Philip Morris International",
            "PYPL": "PayPal Holdings Inc.",
            "QCOM": "QUALCOMM Inc.",
            "RTX": "Raytheon Technologies",
            "SBUX": "Starbucks Corp.",
            "SLB": "SLB",
            "SO": "Southern Co.",
            "SPG": "Simon Property Group",
            "T": "AT&T Inc.",
            "TGT": "Target Corp.",
            "TJX": "TJX Companies Inc.",
            "TMO": "Thermo Fisher Scientific",
            "TSLA": "Tesla Inc.",
            "TXN": "Texas Instruments",
            "UNH": "UnitedHealth Group",
            "UNP": "Union Pacific Corp.",
            "UPS": "United Parcel Service",
            "USB": "U.S. Bancorp",
            "V": "Visa Inc.",
            "VZ": "Verizon Communications",
            "WBA": "Walgreens Boots Alliance",
            "WFC": "Wells Fargo & Co.",
            "WMT": "Walmart Inc.",
            "XOM": "Exxon Mobil Corp."
        ]
        return companyNames[symbol] ?? symbol
    }
}

// MARK: – Market Stat Card
struct MarketStatCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if !change.isEmpty {
                Text(change)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isPositive ? Color(red: 143/255, green: 217/255, blue: 83/255) : .red)
            }
        }
        .padding(16)
        .frame(width: 140)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: – Enhanced Asset Row View
struct EnhancedAssetRowView: View {
    let asset: Asset

    var body: some View {
        HStack(spacing: 12) {
            // Stock Info
            HStack(spacing: 12) {
                // Stock Icon
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 143/255, green: 217/255, blue: 83/255),
                                Color(red: 111/255, green: 170/255, blue: 12/255)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(asset.symbol.prefix(2)))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(asset.symbol)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(asset.companyName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Price Info
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(String(format: "%.2f", asset.price))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Vol: \(asset.volume)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(width: 80)
            
            // Change Info
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: asset.changePercent >= 0 ? "triangle.fill" : "triangle.fill")
                        .font(.caption2)
                        .rotationEffect(.degrees(asset.changePercent >= 0 ? 0 : 180))
                        .foregroundColor(asset.changePercent >= 0 ? Color(red: 143/255, green: 217/255, blue: 83/255) : .red)
                    
                    Text("\(String(format: "%.2f", abs(asset.changePercent)))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(asset.changePercent >= 0 ? Color(red: 143/255, green: 217/255, blue: 83/255) : .red)
                }
                
                Text("\(asset.change >= 0 ? "+" : "")$\(String(format: "%.2f", asset.change))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(width: 80)
        }
        .contentShape(Rectangle())
    }
}

// MARK: – Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView(authVM: AuthViewModel())
        }
        .preferredColorScheme(.dark)
    }
}
