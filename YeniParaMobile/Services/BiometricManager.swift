import LocalAuthentication
import SwiftUI

class BiometricManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isBiometricEnabled = UserDefaults.standard.bool(forKey: "biometricEnabled")
    @Published var biometricType: BiometricType = .none
    
    private let context = LAContext()
    
    init() {
        checkBiometricAvailability()
    }
    
    enum BiometricType {
        case none
        case faceID
        case touchID
        
        var displayName: String {
            switch self {
            case .none:
                return "Biyometrik Yok"
            case .faceID:
                return "Face ID"
            case .touchID:
                return "Touch ID"
            }
        }
        
        var iconName: String {
            switch self {
            case .none:
                return "lock.fill"
            case .faceID:
                return "faceid"
            case .touchID:
                return "touchid"
            }
        }
    }
    
    func checkBiometricAvailability() {
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .faceID:
                biometricType = .faceID
            case .touchID:
                biometricType = .touchID
            case .opticID:
                biometricType = .none  // Vision Pro support
            case .none:
                biometricType = .none
            @unknown default:
                biometricType = .none
            }
        } else {
            biometricType = .none
        }
    }
    
    func authenticate(reason: String = "Uygulamaya erişmek için kimliğinizi doğrulayın") async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Debug logging removed for production
            return false
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            await MainActor.run {
                self.isAuthenticated = success
            }
            
            return success
        } catch {
            // Debug logging removed for production
            return false
        }
    }
    
    func toggleBiometric() {
        isBiometricEnabled.toggle()
        UserDefaults.standard.set(isBiometricEnabled, forKey: "biometricEnabled")
        
        if isBiometricEnabled {
            Task {
                let success = await authenticate(reason: "\(biometricType.displayName) kullanımını etkinleştir")
                if !success {
                    await MainActor.run {
                        self.isBiometricEnabled = false
                        UserDefaults.standard.set(false, forKey: "biometricEnabled")
                    }
                }
            }
        }
    }
    
    func authenticateOnAppLaunch() async {
        guard isBiometricEnabled else { return }
        
        let success = await authenticate()
        if !success {
            // Eğer biyometrik doğrulama başarısız olursa, şifre ile giriş ekranına yönlendir
            await MainActor.run {
                self.isAuthenticated = false
            }
        }
    }
}