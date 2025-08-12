import Security
import Foundation

class KeychainHelper {
    static let shared = KeychainHelper()
    
    private init() {}
    
    func save(_ data: Data, service: String, account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func read(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            return dataTypeRef as? Data
        }
        
        return nil
    }
    
    func delete(service: String, account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    // Token specific methods
    func saveToken(_ token: String, type: TokenType) -> Bool {
        guard let data = token.data(using: .utf8) else { return false }
        return save(data, service: AppConfig.keychainService, account: type.rawValue)
    }
    
    func getToken(type: TokenType) -> String? {
        guard let data = read(service: AppConfig.keychainService, account: type.rawValue),
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        return token
    }
    
    func deleteToken(type: TokenType) -> Bool {
        return delete(service: AppConfig.keychainService, account: type.rawValue)
    }
    
    func saveRefreshToken(_ token: String) -> Bool {
        return saveToken(token, type: .refresh)
    }
    
    func getRefreshToken() -> String? {
        return getToken(type: .refresh)
    }
    
    func saveAccessToken(_ token: String) -> Bool {
        return saveToken(token, type: .access)
    }
    
    func getAccessToken() -> String? {
        return getToken(type: .access)
    }
    
    func clearAllTokens() {
        _ = deleteToken(type: .access)
        _ = deleteToken(type: .refresh)
    }
    
    enum TokenType: String {
        case access = "access_token"
        case refresh = "refresh_token"
    }
}