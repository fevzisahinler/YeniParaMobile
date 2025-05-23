
import SwiftUI

struct HomeView: View {
    @ObservedObject var authVM: AuthViewModel

    @State private var symbols: [String] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Semboller yükleniyor…")
                } else {
                    List(symbols, id: \.self) { sym in
                        NavigationLink(value: sym) {
                            Text(sym)
                                .padding(.vertical, 8)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Semboller")
            .navigationDestination(for: String.self) { sym in
                SymbolDetailView(symbol: sym)
            }
            .onAppear { Task { await fetchSymbols() } }
        }
    }

    private func fetchSymbols() async {
        isLoading = true
        defer { isLoading = false }
        guard let url = URL(string: "http://localhost:4000/symbols") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            struct Resp: Decodable { let data: [String] }
            let resp = try JSONDecoder().decode(Resp.self, from: data)
            // ".US" uzantısını at
            symbols = resp.data.map { $0.replacingOccurrences(of: ".US", with: "") }
        } catch {
            print("Sembol yükleme hatası:", error)
        }
    }
}
