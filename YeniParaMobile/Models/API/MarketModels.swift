import Foundation

// MARK: - Symbol Models
struct Symbol: Codable {
    let code: String
    let name: String
    let exchange: String
    let logoPath: String
    
    enum CodingKeys: String, CodingKey {
        case code, name, exchange
        case logoPath = "logo_path"
    }
}

struct SymbolsResponse: Codable {
    let success: Bool
    let data: [Symbol]
    let pagination: PaginationInfo
    let meta: MetaInfo
}

struct PaginationInfo: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let pages: Int
}

struct MetaInfo: Codable {
    let timestamp: Int64
}

// MARK: - Fundamental Data Models
struct FundamentalResponse: Codable {
    let success: Bool
    let data: FundamentalData
}

struct FundamentalData: Codable {
    let symbolCode: String
    let code: String
    let name: String
    let exchange: String
    let currency: String
    let country: String?
    let isin: String?
    let ipoDate: String?
    let sector: String?
    let industry: String?
    let description: String?
    let address: String?
    let webUrl: String?
    let logoPath: String
    let logoUrl: String?
    let marketCapitalization: Double?
    let peRatio: Double?
    let earningsShare: Double?
    let dividendYield: Double?
    let wallStreetTargetPrice: Double?
    let analystRating: Int?
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case symbolCode = "symbol_code"
        case code, name, exchange, currency, country, isin, sector, industry, description, address
        case ipoDate = "ipo_date"
        case webUrl = "web_url"
        case logoPath = "logo_path"
        case logoUrl = "logo_url"
        case marketCapitalization = "market_capitalization"
        case peRatio = "pe_ratio"
        case earningsShare = "earnings_share"
        case dividendYield = "dividend_yield"
        case wallStreetTargetPrice = "wall_street_target_price"
        case analystRating = "analyst_rating"
        case updatedAt = "updated_at"
    }
}

// MARK: - Candle Data Models
struct CandleResponse: Codable {
    let symbol: String
    let candles: [CandleData]
    let meta: CandleMetaInfo
}

struct CandleData: Codable {
    let timestamp: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
}

struct CandleMetaInfo: Codable {
    let timestamp: Int64
    let count: Int
}
