import Foundation

// MARK: - API Error Types
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(Int)
    case serverErrorWithMessage(Int, String)
    case decodingError
    case networkError
    case noData
    case timeout
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Geçersiz URL"
        case .invalidResponse:
            return "Geçersiz sunucu yanıtı"
        case .unauthorized:
            return "Oturumunuz sonlanmış. Lütfen tekrar giriş yapın."
        case .serverError(let code):
            return "Sunucu hatası: \(code)"
        case .serverErrorWithMessage(_, let message):
            return message
        case .decodingError:
            return "Veri işleme hatası"
        case .networkError:
            return "İnternet bağlantınızı kontrol edin"
        case .noData:
            return "Veri bulunamadı"
        case .timeout:
            return "İstek zaman aşımına uğradı"
        case .cancelled:
            return "İstek iptal edildi"
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .networkError, .timeout:
            return true
        case .serverError(let code) where code >= 500:
            return true
        default:
            return false
        }
    }
    
    var statusCode: Int? {
        switch self {
        case .serverError(let code):
            return code
        case .serverErrorWithMessage(let code, _):
            return code
        case .unauthorized:
            return 401
        default:
            return nil
        }
    }
}

// MARK: - Error Response Model
struct ErrorResponse: Codable {
    let error: String?
    let message: String?
    let success: Bool?
    let code: String?
    let details: [String: String]?
    
    var displayMessage: String {
        return error ?? message ?? "Bilinmeyen bir hata oluştu"
    }
}
