
import SwiftUI
import Charts

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

struct CandleData: Identifiable {
    let id = UUID()
    let timestamp: Date
    let open, high, low, close, volume: Double
}

struct SymbolDetailView: View {
    let symbol: String

    @State private var candles: [CandleData] = []
    @State private var isLoading = false

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Veriler yükleniyor…")
            } else if candles.isEmpty {
                Text("Veri yok.")
                    .foregroundColor(.secondary)
            } else {
                Chart(candles) { c in
                    LineMark(
                        x: .value("Tarih", c.timestamp),
                        y: .value("Kapanış", c.close)
                    )
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisGridLine(); AxisTick()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .frame(height: 300)
                .padding()

                List(candles) { c in
                    HStack {
                        Text(c.timestamp, format: .dateTime.day().month().year())
                        Spacer()
                        Text(c.close, format: .number.precision(.fractionLength(2)))
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(symbol)
        .onAppear { Task { await fetchCandles() } }
    }

    private func fetchCandles() async {
        isLoading = true
        defer { isLoading = false }

        let symParam = symbol + ".US"
        var comp = URLComponents(string: "http://localhost:4000/candles/1d")!
        comp.queryItems = [
            .init(name: "symbol", value: symParam),
            .init(name: "limit", value: "100000")
        ]
        guard let url = comp.url else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let resp = try JSONDecoder().decode(HistoricalResponse.self, from: data)
            let iso = ISO8601DateFormatter()
            candles = resp.data.compactMap { api in
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
            .sorted { $0.timestamp < $1.timestamp }
        } catch {
            print("Candle yükleme hatası:", error)
        }
    }
}
