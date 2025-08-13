import Foundation

// MARK: - News Models
struct NewsResponse: Codable {
    let data: [NewsItem]
    let pagination: NewsPagination
    let success: Bool
}

struct NewsItem: Codable, Identifiable {
    let id: Int
    let symbolCode: String
    let headline: String
    let summary: String
    let author: String
    let url: String
    let publishedAt: String
    let importance: String
    let sentiment: String
    let relatedSymbols: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case symbolCode = "symbol_code"
        case headline
        case summary
        case author
        case url
        case publishedAt = "published_at"
        case importance
        case sentiment
        case relatedSymbols = "related_symbols"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Computed properties
    var importanceLevel: Int {
        return Int(importance) ?? 3
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        if let date = formatter.date(from: publishedAt) {
            let now = Date()
            let components = Calendar.current.dateComponents([.hour, .minute, .day], from: date, to: now)
            
            if let days = components.day, days > 0 {
                return days == 1 ? "1 gün önce" : "\(days) gün önce"
            } else if let hours = components.hour, hours > 0 {
                return hours == 1 ? "1 saat önce" : "\(hours) saat önce"
            } else if let minutes = components.minute, minutes > 0 {
                return minutes == 1 ? "1 dakika önce" : "\(minutes) dakika önce"
            } else {
                return "Şimdi"
            }
        }
        
        return publishedAt
    }
    
    var sentimentEmoji: String {
        switch sentiment.lowercased() {
        case "positive", "bullish":
            return "🟢"
        case "negative", "bearish":
            return "🔴"
        default:
            return "⚪️"
        }
    }
    
    var importanceEmoji: String {
        switch importanceLevel {
        case 5:
            return "🔥"
        case 4:
            return "⭐️"
        case 3:
            return "📰"
        default:
            return "📄"
        }
    }
}

struct NewsPagination: Codable {
    let currentPage: Int
    let limit: Int
    let totalItems: Int
    let totalPages: Int
    
    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case limit
        case totalItems = "total_items"
        case totalPages = "total_pages"
    }
}

// MARK: - News Service
class NewsService {
    static let shared = NewsService()
    private let baseURL = "http://localhost:4000/api/v1/news"
    
    private init() {}
    
    func getNews(page: Int = 1, limit: Int = 10) async throws -> NewsResponse {
        guard let url = URL(string: "\(baseURL)?page=\(page)&limit=\(limit)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add auth token
        if let token = TokenManager.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(NewsResponse.self, from: data)
        
        guard result.success else {
            throw URLError(.cannotParseResponse)
        }
        
        return result
    }
    
    func getNewsForSymbol(_ symbol: String, page: Int = 1, limit: Int = 10) async throws -> NewsResponse {
        guard let url = URL(string: "\(baseURL)?symbol=\(symbol)&page=\(page)&limit=\(limit)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = TokenManager.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(NewsResponse.self, from: data)
        
        guard result.success else {
            throw URLError(.cannotParseResponse)
        }
        
        return result
    }
}