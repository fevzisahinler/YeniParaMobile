import SwiftUI

// MARK: – Models from your API

struct SymbolsResponse: Decodable {
    let data: [String]
    let success: Bool
}

// You already have in SymbolDetailView.swift:
//   struct CandleAPIModel: Decodable { … }
//   struct HistoricalResponse: Decodable { let data: [CandleAPIModel] }

// MARK: – Asset model for the list

struct Asset: Identifiable {
    let id = UUID()
    let symbol: String         // e.g. "AAPL"
    let price: Double          // latest close
    let change: Double         // (latest - previous)/previous
    let iconName: String       // matches an asset in Assets.xcassets
}

enum TimeFrame: String, CaseIterable, Identifiable {
    case oneDay     = "1G"
    case oneHour    = "1H"
    case oneMonth   = "1A"
    case threeMonth = "3A"
    case oneYear    = "1Y"
    var id: String { rawValue }
}

// MARK: – HomeView

struct HomeView: View {
    @ObservedObject var authVM: AuthViewModel

    @State private var assets: [Asset] = []
    @State private var selectedTimeFrame: TimeFrame = .oneDay
    @State private var isLoading = false
    @State private var loadingError: String?

    var body: some View {
        ZStack {
            Color(red: 28/255, green: 29/255, blue: 36/255)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                timeframePicker

                if isLoading {
                    ProgressView("Yükleniyor…")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let err = loadingError {
                    Text(err)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(assets) { asset in
                                NavigationLink(destination: SymbolDetailView(symbol: asset.symbol)) {
                                    AssetRowView(asset: asset)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear(perform: loadSP100)
    }

    // MARK: – Header

    private var header: some View {
        VStack(spacing: 4) {
            HStack {
                Button { } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                Spacer()
                Text("SP100")
                    .font(.title2).bold()
                    .foregroundColor(.white)
                Spacer()
                Button { } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Text("\(assets.count) Varlık")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 8)
        }
    }

    // MARK: – Picker

    private var timeframePicker: some View {
        Picker("", selection: $selectedTimeFrame) {
            ForEach(TimeFrame.allCases) { tf in
                Text(tf.rawValue).tag(tf)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: – Data Loading

    private func loadSP100() {
        Task {
            do {
                isLoading = true
                loadingError = nil

                // 1) Fetch symbol list
                let symbolsURL = URL(string: "http://localhost:4000/symbols")!
                let (symbolsData, _) = try await URLSession.shared.data(from: symbolsURL)
                let symbolsResp = try JSONDecoder().decode(SymbolsResponse.self, from: symbolsData)

                var temp: [Asset] = []

                // 2) For each symbol, fetch the last 2 candles via HistoricalResponse
                for raw in symbolsResp.data {
                    let trimmed = raw.replacingOccurrences(of: ".US", with: "")

                    var comps = URLComponents(string: "http://localhost:4000/candles/1d")!
                    comps.queryItems = [
                        .init(name: "symbol", value: raw),
                        .init(name: "limit", value: "2")
                    ]
                    let candlesURL = comps.url!
                    let (candlesData, _) = try await URLSession.shared.data(from: candlesURL)

                    // decode into your existing HistoricalResponse
                    let histResp = try JSONDecoder()
                        .decode(HistoricalResponse.self, from: candlesData)

                    // sort descending by timestamp
                    let sorted = histResp.data.sorted { $0.timestamp > $1.timestamp }
                    guard sorted.count >= 2 else { continue }
                    let latest   = sorted[0]
                    let previous = sorted[1]

                    let price  = latest.close
                    let change = (latest.close - previous.close) / previous.close

                    temp.append(.init(
                        symbol: trimmed,
                        price: price,
                        change: change,
                        iconName: trimmed
                    ))
                }

                await MainActor.run {
                    self.assets = temp
                }
            } catch {
                await MainActor.run {
                    loadingError = "Veri yüklenirken hata: \(error.localizedDescription)"
                }
            }
            await MainActor.run { isLoading = false }
        }
    }
}

// MARK: – Row View

struct AssetRowView: View {
    let asset: Asset

    var body: some View {
        HStack(spacing: 12) {
            Image(asset.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)

            Text(asset.symbol)
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(asset.price, format: .currency(code: "USD"))
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text(asset.change, format: .percent.precision(.fractionLength(2)))
                    .font(.footnote)
                    .foregroundColor(asset.change >= 0 ? .green : .red)
            }
            .frame(width: 80)

            Text(asset.change, format: .percent.precision(.fractionLength(2)))
                .font(.footnote)
                .foregroundColor(asset.change >= 0 ? .green : .red)
        }
    }
}

// MARK: – Preview

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView(authVM: AuthViewModel())
        }
    }
}
