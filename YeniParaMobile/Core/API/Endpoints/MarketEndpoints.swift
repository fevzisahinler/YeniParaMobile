import Foundation

// MARK: - Market Data Endpoints
enum MarketEndpoint: APIEndpoint {
    case getSymbols(page: Int, limit: Int, sort: String, order: String)
    case searchSymbols(query: String)
    case getFundamentalData(symbol: String)
    case getCandleData(symbol: String, timeframe: String, from: String?, to: String?)
    case getCompanyLogo(symbol: String)
    case getMarketStatus
    case getTopMovers(type: MoverType)
    
    enum MoverType: String {
        case gainers = "gainers"
        case losers = "losers"
        case volume = "volume"
    }
    
    var path: String {
        switch self {
        case .getSymbols:
            return "/api/v1/symbols"
        case .searchSymbols:
            return "/api/v1/symbols/search"
        case .getFundamentalData(let symbol):
            return "/api/v1/fundamental/\(symbol)"
        case .getCandleData:
            return "/api/v1/market/candles"
        case .getCompanyLogo(let symbol):
            return "/api/v1/logos/\(symbol).jpeg"
        case .getMarketStatus:
            return "/api/v1/market/status"
        case .getTopMovers:
            return "/api/v1/market/top-movers"
        }
    }
    
    var method: HTTPMethod {
        return .GET
    }
    
    var requiresAuth: Bool {
        return true
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .getSymbols(let page, let limit, let sort, let order):
            return [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "sort", value: sort),
                URLQueryItem(name: "order", value: order)
            ]
            
        case .searchSymbols(let query):
            return [URLQueryItem(name: "q", value: query)]
            
        case .getCandleData(let symbol, let timeframe, let from, let to):
            var items = [
                URLQueryItem(name: "symbol", value: symbol),
                URLQueryItem(name: "timeframe", value: timeframe)
            ]
            if let from = from {
                items.append(URLQueryItem(name: "from", value: from))
            }
            if let to = to {
                items.append(URLQueryItem(name: "to", value: to))
            }
            return items
            
        case .getTopMovers(let type):
            return [URLQueryItem(name: "type", value: type.rawValue)]
            
        default:
            return nil
        }
    }
}
