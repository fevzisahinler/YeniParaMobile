import SwiftUI
import Charts

struct CandleData: Identifiable {
    let id = UUID()
    let timestamp: Date
    let open, high, low, close, volume: Double
}

enum ChartType: String, CaseIterable {
    case line = "line"
    case area = "area"
    
    var displayName: String {
        switch self {
        case .line: return "Çizgi"
        case .area: return "Alan"
        }
    }
    
    var icon: String {
        switch self {
        case .line: return "chart.line.uptrend.xyaxis"
        case .area: return "chart.area"
        }
    }
}

struct SymbolDetailView: View {
    let symbol: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var candles: [CandleData] = []
    @State private var isLoading = false
    @State private var selectedChartType: ChartType = .line
    @State private var currentPrice: Double = 0
    @State private var priceChange: Double = 0
    @State private var priceChangePercent: Double = 0
    @State private var volume24h: Double = 0
    @State private var high24h: Double = 0
    @State private var low24h: Double = 0
    @State private var openPrice: Double = 0
    @State private var marketCap: String = "N/A"
    @State private var isInWatchlist: Bool = false
    
    private var isPositiveChange: Bool { priceChange >= 0 }
    private var changeColor: Color {
        isPositiveChange ? Color(red: 143/255, green: 217/255, blue: 83/255) : .red
    }
    
    private var companyName: String {
        getCompanyName(for: symbol)
    }

    var body: some View {
        ZStack {
            // Background
            Color(red: 28/255, green: 29/255, blue: 36/255)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Navigation Bar
                customNavigationBar
                
                if isLoading {
                    loadingView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header with price info
                            headerSection
                            
                            // Chart controls
                            chartControlsSection
                            
                            // Main chart
                            chartSection
                            
                            // Statistics section
                            statisticsSection
                            
                            // Market info
                            marketInfoSection
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task { await fetchCandles() }
        }
        .refreshable {
            Task { await fetchCandles() }
        }
    }
    
    // MARK: - Custom Navigation Bar
    private var customNavigationBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(symbol)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(companyName)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: { isInWatchlist.toggle() }) {
                    Image(systemName: isInWatchlist ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundColor(isInWatchlist ? .red : .white)
                        .frame(width: 44, height: 44)
                }
                
                Button(action: { }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(red: 28/255, green: 29/255, blue: 36/255))
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                // Symbol and company info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 12)
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
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(String(symbol.prefix(2)))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(symbol)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("NASDAQ")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                
                Spacer()
                
                // Live indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(red: 143/255, green: 217/255, blue: 83/255))
                        .frame(width: 8, height: 8)
                    
                    Text("CANLI")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 143/255, green: 217/255, blue: 83/255))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(red: 143/255, green: 217/255, blue: 83/255).opacity(0.2))
                .cornerRadius(12)
            }
            
            // Price information
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("$\(String(format: "%.2f", currentPrice))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: isPositiveChange ? "triangle.fill" : "triangle.fill")
                                .font(.caption)
                                .rotationEffect(.degrees(isPositiveChange ? 0 : 180))
                                .foregroundColor(changeColor)
                            
                            Text("\(isPositiveChange ? "+" : "")$\(String(format: "%.2f", priceChange))")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(changeColor)
                        }
                        
                        Text("\(isPositiveChange ? "+" : "")\(String(format: "%.2f", priceChangePercent))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(changeColor)
                    }
                }
                
                // Quick stats
                HStack(spacing: 20) {
                    StatItem(title: "Açılış", value: "$\(String(format: "%.2f", openPrice))", color: .white.opacity(0.8))
                    StatItem(title: "Günlük Yüksek", value: "$\(String(format: "%.2f", high24h))", color: .white.opacity(0.8))
                    StatItem(title: "Günlük Düşük", value: "$\(String(format: "%.2f", low24h))", color: .white.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Chart Controls Section
    private var chartControlsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Grafik Türü")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("1 Günlük Veri")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            HStack(spacing: 12) {
                ForEach(ChartType.allCases, id: \.rawValue) { chartType in
                    Button(action: {
                        selectedChartType = chartType
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: chartType.icon)
                                .font(.caption)
                            Text(chartType.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(selectedChartType == chartType ? .black : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedChartType == chartType
                                ? Color(red: 143/255, green: 217/255, blue: 83/255)
                                : Color.white.opacity(0.1)
                        )
                        .cornerRadius(20)
                    }
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Chart Section
    private var chartSection: some View {
        VStack(spacing: 12) {
            if candles.isEmpty {
                Text("Grafik verisi yükleniyor...")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(height: 300)
            } else {
                Chart(candles) { candle in
                    if selectedChartType == .line {
                        LineMark(
                            x: .value("Tarih", candle.timestamp),
                            y: .value("Kapanış", candle.close)
                        )
                        .foregroundStyle(Color(red: 143/255, green: 217/255, blue: 83/255))
                        .interpolationMethod(.catmullRom)
                    } else {
                        AreaMark(
                            x: .value("Tarih", candle.timestamp),
                            y: .value("Kapanış", candle.close)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 143/255, green: 217/255, blue: 83/255).opacity(0.6),
                                    Color(red: 143/255, green: 217/255, blue: 83/255).opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.white.opacity(0.2))
                        AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.white.opacity(0.5))
                        AxisValueLabel()
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.white.opacity(0.2))
                        AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.white.opacity(0.5))
                        AxisValueLabel()
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .frame(height: 300)
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("İstatistikler")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(title: "Hacim", value: String(format: "%.1fM", volume24h / 1_000_000))
                StatCard(title: "Piyasa Değeri", value: marketCap)
                StatCard(title: "P/E Oranı", value: "24.5")
                StatCard(title: "52H Yüksek", value: "$\(String(format: "%.2f", high24h * 1.2))")
                StatCard(title: "52H Düşük", value: "$\(String(format: "%.2f", low24h * 0.8))")
                StatCard(title: "Beta", value: "1.2")
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Market Info Section
    private var marketInfoSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Hakkında")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            VStack(spacing: 12) {
                InfoRow(title: "Şirket Adı", value: companyName)
                InfoRow(title: "Sektör", value: "Teknoloji")
                InfoRow(title: "Borsa", value: "NASDAQ")
                InfoRow(title: "Ülke", value: "ABD")
                InfoRow(title: "Para Birimi", value: "USD")
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Loading View
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
    
    // MARK: - Data Fetching
    private func fetchCandles() async {
        isLoading = true
        defer { isLoading = false }

        let symParam = symbol + ".US"
        var comp = URLComponents(string: "http://localhost:4000/candles/1d")!
        comp.queryItems = [
            .init(name: "symbol", value: symParam),
            .init(name: "limit", value: "30")
        ]
        guard let url = comp.url else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let resp = try JSONDecoder().decode(HistoricalResponse.self, from: data)
            let iso = ISO8601DateFormatter()
            
            let candlesData: [CandleData] = resp.data.compactMap { (api: CandleAPIModel) -> CandleData? in
                guard let d = iso.date(from: api.timestamp) else { return nil }
                return CandleData(
                    timestamp: d,
                    open: api.open,
                    high: api.high,
                    low: api.low,
                    close: api.close,
                    volume: api.volume
                )
            }
            .sorted { (a: CandleData, b: CandleData) -> Bool in
                return a.timestamp < b.timestamp
            }
            
            await MainActor.run {
                self.candles = candlesData
                
                if let latest = candlesData.last, candlesData.count >= 2 {
                    let previous = candlesData[candlesData.count - 2]
                    
                    self.currentPrice = latest.close
                    self.openPrice = latest.open
                    self.high24h = latest.high
                    self.low24h = latest.low
                    self.volume24h = latest.volume
                    self.priceChange = latest.close - previous.close
                    self.priceChangePercent = (self.priceChange / previous.close) * 100
                    self.marketCap = String(format: "%.1fB", Double.random(in: 1...500))
                }
            }
        } catch {
            print("Candle yükleme hatası:", error)
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

// MARK: - Supporting Views
struct StatItem: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
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
                .foregroundColor(.white.opacity(0.7))
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(16)
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

struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.vertical, 4)
    }
}

// MARK: – Preview
struct SymbolDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SymbolDetailView(symbol: "AAPL")
        }
        .preferredColorScheme(.dark)
    }
}
