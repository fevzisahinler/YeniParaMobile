import Foundation

// MARK: - Quiz Endpoints
enum QuizEndpoint: APIEndpoint {
    case getQuestions
    case submitAnswers([String: Int])
    case getStatus
    case getResult
    
    var path: String {
        switch self {
        case .getQuestions:
            return "/api/v1/quiz/questions"
        case .submitAnswers:
            return "/api/v1/quiz/submit"
        case .getStatus:
            return "/api/v1/quiz/status"
        case .getResult:
            return "/api/v1/quiz/result"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getQuestions, .getStatus, .getResult:
            return .GET
        case .submitAnswers:
            return .POST
        }
    }
    
    var requiresAuth: Bool {
        switch self {
        case .getQuestions:
            return false
        default:
            return true
        }
    }
    
    var body: Data? {
        switch self {
        case .submitAnswers(let answers):
            return encodeBody(QuizSubmitRequest(answers: answers))
        default:
            return nil
        }
    }
}
