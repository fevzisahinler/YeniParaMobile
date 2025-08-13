import Foundation

// MARK: - Macro Data Models
struct MacroSummaryResponse: Codable {
    let data: MacroSummary
    let success: Bool
}

struct MacroSummary: Codable {
    let gdp: MacroGDP
    let cpi: MacroCPI
    let fedRate: MacroFedRate
    let unemployment: MacroUnemployment
    let oilPrice: MacroOilPrice
    let retailSales: MacroRetailSales
    let lastUpdated: String
    
    enum CodingKeys: String, CodingKey {
        case gdp, cpi
        case fedRate = "fed_rate"
        case unemployment
        case oilPrice = "oil_price"
        case retailSales = "retail_sales"
        case lastUpdated = "last_updated"
    }
}

struct MacroGDP: Codable {
    let date: String
    let value: Double
    let yoyChange: Double
    let qoqChange: Double
    
    enum CodingKeys: String, CodingKey {
        case date, value
        case yoyChange = "yoy_change"
        case qoqChange = "qoq_change"
    }
}

struct MacroCPI: Codable {
    let date: String
    let value: Double
    let yoyInflation: Double
    let momChange: Double
    
    enum CodingKeys: String, CodingKey {
        case date, value
        case yoyInflation = "yoy_inflation"
        case momChange = "mom_change"
    }
}

struct MacroFedRate: Codable {
    let date: String
    let rate: Double
    let change: Double
}

struct MacroUnemployment: Codable {
    let date: String
    let rate: Double
    let change: Double
}

struct MacroOilPrice: Codable {
    let date: String
    let price: Double
    let change: Double
    let percentChange: Double
    
    enum CodingKeys: String, CodingKey {
        case date, price, change
        case percentChange = "percent_change"
    }
}

struct MacroRetailSales: Codable {
    let date: String
    let value: Double
    let yoyChange: Double
    let momChange: Double
    
    enum CodingKeys: String, CodingKey {
        case date, value
        case yoyChange = "yoy_change"
        case momChange = "mom_change"
    }
}

// MARK: - Historical Data Models
struct MacroHistoricalResponse<T: Codable>: Codable {
    let data: MacroHistoricalData<T>
    let success: Bool
}

struct MacroHistoricalData<T: Codable>: Codable {
    let count: Int
    let data: [T]
}

struct GDPHistorical: Codable {
    let date: String
    let value: Double
    let yoyChange: Double
    let qoqChange: Double
    
    enum CodingKeys: String, CodingKey {
        case date, value
        case yoyChange = "yoy_change"
        case qoqChange = "qoq_change"
    }
}

struct CPIHistorical: Codable {
    let date: String
    let value: Double
    let yoyInflation: Double
    let momChange: Double
    
    enum CodingKeys: String, CodingKey {
        case date, value
        case yoyInflation = "yoy_inflation"
        case momChange = "mom_change"
    }
}

struct FedRateHistorical: Codable {
    let date: String
    let rate: Double
    let change: Double
}

struct UnemploymentHistorical: Codable {
    let date: String
    let rate: Double
    let change: Double
}

struct OilPriceHistorical: Codable {
    let date: String
    let price: Double
    let change: Double
    let percentChange: Double
    
    enum CodingKeys: String, CodingKey {
        case date, price, change
        case percentChange = "percent_change"
    }
}

struct RetailSalesHistorical: Codable {
    let date: String
    let value: Double
    let yoyChange: Double
    let momChange: Double
    
    enum CodingKeys: String, CodingKey {
        case date, value
        case yoyChange = "yoy_change"
        case momChange = "mom_change"
    }
}

// MARK: - Macro Service
class MacroService {
    static let shared = MacroService()
    private let baseURL = "http://192.168.1.210:4000/api/v1/market/macro"
    
    private init() {}
    
    // MARK: - Get Macro Summary
    func getMacroSummary() async throws -> MacroSummary {
        guard let url = URL(string: "\(baseURL)/summary") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add auth token if available
        if let token = TokenManager.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(MacroSummaryResponse.self, from: data)
        
        guard result.success else {
            throw URLError(.cannotParseResponse)
        }
        
        return result.data
    }
    
    // MARK: - Get GDP Historical Data
    func getGDPHistorical(limit: Int = 100) async throws -> [GDPHistorical] {
        guard let url = URL(string: "\(baseURL)/gdp?limit=\(limit)") else {
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
        let result = try decoder.decode(MacroHistoricalResponse<GDPHistorical>.self, from: data)
        
        guard result.success else {
            throw URLError(.cannotParseResponse)
        }
        
        return result.data.data
    }
    
    // MARK: - Get CPI Historical Data
    func getCPIHistorical(limit: Int = 100) async throws -> [CPIHistorical] {
        guard let url = URL(string: "\(baseURL)/cpi?limit=\(limit)") else {
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
        let result = try decoder.decode(MacroHistoricalResponse<CPIHistorical>.self, from: data)
        
        guard result.success else {
            throw URLError(.cannotParseResponse)
        }
        
        return result.data.data
    }
    
    // MARK: - Get Fed Rate Historical Data
    func getFedRateHistorical(limit: Int = 100) async throws -> [FedRateHistorical] {
        guard let url = URL(string: "\(baseURL)/fed-rate?limit=\(limit)") else {
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
        let result = try decoder.decode(MacroHistoricalResponse<FedRateHistorical>.self, from: data)
        
        guard result.success else {
            throw URLError(.cannotParseResponse)
        }
        
        return result.data.data
    }
    
    // MARK: - Get Unemployment Historical Data
    func getUnemploymentHistorical(limit: Int = 100) async throws -> [UnemploymentHistorical] {
        guard let url = URL(string: "\(baseURL)/unemployment?limit=\(limit)") else {
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
        let result = try decoder.decode(MacroHistoricalResponse<UnemploymentHistorical>.self, from: data)
        
        guard result.success else {
            throw URLError(.cannotParseResponse)
        }
        
        return result.data.data
    }
    
    // MARK: - Get Oil Price Historical Data
    func getOilPriceHistorical(limit: Int = 100) async throws -> [OilPriceHistorical] {
        guard let url = URL(string: "\(baseURL)/oil?limit=\(limit)") else {
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
        let result = try decoder.decode(MacroHistoricalResponse<OilPriceHistorical>.self, from: data)
        
        guard result.success else {
            throw URLError(.cannotParseResponse)
        }
        
        return result.data.data
    }
    
    // MARK: - Get Retail Sales Historical Data
    func getRetailSalesHistorical(limit: Int = 100) async throws -> [RetailSalesHistorical] {
        guard let url = URL(string: "\(baseURL)/retail-sales?limit=\(limit)") else {
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
        let result = try decoder.decode(MacroHistoricalResponse<RetailSalesHistorical>.self, from: data)
        
        guard result.success else {
            throw URLError(.cannotParseResponse)
        }
        
        return result.data.data
    }
}