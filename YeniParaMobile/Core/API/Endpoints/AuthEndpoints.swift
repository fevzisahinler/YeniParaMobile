import Foundation

// MARK: - Auth Endpoints
enum AuthEndpoint: APIEndpoint {
    case login(email: String, password: String)
    case register(RegisterRequest)
    case verifyEmail(userId: Int, code: String)
    case resendOTP(userId: Int)
    case refreshToken(refreshToken: String)
    case forgotPassword(email: String)
    case resetPassword(email: String, code: String, newPassword: String)
    case logout
    
    var path: String {
        switch self {
        case .login:
            return "/api/v1/auth/login"
        case .register:
            return "/api/v1/auth/register"
        case .verifyEmail:
            return "/api/v1/auth/verify-email"
        case .resendOTP:
            return "/api/v1/auth/resend-otp"
        case .refreshToken:
            return "/api/v1/auth/refresh"
        case .forgotPassword:
            return "/api/v1/auth/forgot-password"
        case .resetPassword:
            return "/api/v1/auth/reset-password"
        case .logout:
            return "/api/v1/auth/logout"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .logout:
            return .DELETE
        default:
            return .POST
        }
    }
    
    var requiresAuth: Bool {
        switch self {
        case .logout, .refreshToken:
            return true
        default:
            return false
        }
    }
    
    var body: Data? {
        switch self {
        case .login(let email, let password):
            return encodeBody(LoginRequest(email: email, password: password))
            
        case .register(let request):
            return encodeBody(request)
            
        case .verifyEmail(let userId, let code):
            struct VerifyEmailRequest: Encodable {
                let user_id: Int
                let code: String
            }
            return encodeBody(VerifyEmailRequest(user_id: userId, code: code))
            
        case .resendOTP(let userId):
            struct ResendOTPRequest: Encodable {
                let user_id: Int
            }
            return encodeBody(ResendOTPRequest(user_id: userId))
            
        case .refreshToken(let refreshToken):
            return encodeBody(["refresh_token": refreshToken])
            
        case .forgotPassword(let email):
            return encodeBody(["email": email])
            
        case .resetPassword(let email, let code, let newPassword):
            return encodeBody([
                "email": email,
                "code": code,
                "new_password": newPassword
            ])
            
        case .logout:
            return nil
        }
    }
}
