import SwiftUI
import LocalAuthentication

struct SecurityView: View {
    @ObservedObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var biometricManager = BiometricManager()
    
    @State private var biometricEnabled = false
    @State private var twoFactorEnabled = false
    @State private var pinEnabled = false
    @State private var showChangePassword = false
    @State private var showPinSetup = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    Spacer()
                    
                    Text("Güvenlik")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .opacity(0)
                }
                .padding(.horizontal, AppConstants.screenPadding)
                .padding(.vertical, 16)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Güvenlik Durumu
                        SecurityStatusCard()
                        
                        // Kimlik Doğrulama
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Kimlik Doğrulama")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal, AppConstants.screenPadding)
                            
                            VStack(spacing: 1) {
                                SecurityToggleRow(
                                    icon: "number.circle",
                                    title: "PIN Kodu",
                                    subtitle: "4 haneli güvenlik kodu",
                                    isOn: $pinEnabled,
                                    onToggle: togglePin
                                )
                            }
                            .background(AppColors.cardBackground)
                            .cornerRadius(AppConstants.cornerRadius)
                            .padding(.horizontal, AppConstants.screenPadding)
                        }
                        
                        // Şifre Yönetimi
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Şifre Yönetimi")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal, AppConstants.screenPadding)
                            
                            VStack(spacing: 1) {
                                SecurityActionRow(
                                    icon: "key",
                                    title: "Şifreyi Değiştir",
                                    subtitle: "Son değişiklik: 30 gün önce",
                                    action: { showChangePassword = true }
                                )
                                
                                Divider()
                                    .background(AppColors.cardBorder)
                                    .padding(.leading, 60)
                                
                                SecurityActionRow(
                                    icon: "envelope",
                                    title: "Kurtarma E-postası",
                                    subtitle: "user@example.com",
                                    action: updateRecoveryEmail
                                )
                            }
                            .background(AppColors.cardBackground)
                            .cornerRadius(AppConstants.cornerRadius)
                            .padding(.horizontal, AppConstants.screenPadding)
                        }
                        
                        // Gizlilik
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Gizlilik")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal, AppConstants.screenPadding)
                            
                            VStack(spacing: 1) {
                                SecurityActionRow(
                                    icon: "eye.slash",
                                    title: "Gizlilik Ayarları",
                                    subtitle: "Profil görünürlüğü",
                                    action: showPrivacySettings
                                )
                                
                                Divider()
                                    .background(AppColors.cardBorder)
                                    .padding(.leading, 60)
                                
                                SecurityActionRow(
                                    icon: "clock.arrow.circlepath",
                                    title: "Giriş Geçmişi",
                                    subtitle: "Son 10 giriş",
                                    action: showLoginHistory
                                )
                                
                                Divider()
                                    .background(AppColors.cardBorder)
                                    .padding(.leading, 60)
                                
                                SecurityActionRow(
                                    icon: "iphone",
                                    title: "Aktif Cihazlar",
                                    subtitle: "2 cihaz bağlı",
                                    action: showActiveDevices
                                )
                            }
                            .background(AppColors.cardBackground)
                            .cornerRadius(AppConstants.cornerRadius)
                            .padding(.horizontal, AppConstants.screenPadding)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Güvenlik Uyarısı", isPresented: $showAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func toggleBiometric() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // Biometric authentication is available
        } else {
            alertMessage = "Cihazınız biyometrik doğrulamayı desteklemiyor"
            showAlert = true
            biometricEnabled = false
        }
    }
    
    private func toggleTwoFactor() {
        if twoFactorEnabled {
            alertMessage = "İki faktörlü doğrulama aktif edildi"
        } else {
            alertMessage = "İki faktörlü doğrulama devre dışı bırakıldı"
        }
        showAlert = true
    }
    
    private func togglePin() {
        if pinEnabled {
            showPinSetup = true
        }
    }
    
    private func updateRecoveryEmail() {
        // Kurtarma e-postası güncelleme
    }
    
    private func showPrivacySettings() {
        // Gizlilik ayarları
    }
    
    private func showLoginHistory() {
        // Giriş geçmişi
    }
    
    private func showActiveDevices() {
        // Aktif cihazlar
    }
}

struct SecurityStatusCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 48))
                .foregroundColor(AppColors.primary)
            
            VStack(spacing: 4) {
                Text("Hesabınız Güvende")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("3 güvenlik özelliği aktif")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            HStack(spacing: 24) {
                SecurityStatusItem(icon: "lock.fill", isActive: true)
                SecurityStatusItem(icon: "faceid", isActive: true)
                SecurityStatusItem(icon: "shield.fill", isActive: true)
                SecurityStatusItem(icon: "number.circle.fill", isActive: false)
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [
                    AppColors.cardBackground,
                    AppColors.primary.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(AppConstants.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .stroke(AppColors.primary.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, AppConstants.screenPadding)
    }
}

struct SecurityStatusItem: View {
    let icon: String
    let isActive: Bool
    
    var body: some View {
        Image(systemName: icon)
            .font(.title2)
            .foregroundColor(isActive ? AppColors.primary : AppColors.textTertiary)
    }
}

struct SecurityToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppColors.primary)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppColors.primary)
                .onChange(of: isOn) { _ in
                    onToggle()
                }
        }
        .padding(.horizontal, AppConstants.screenPadding)
        .padding(.vertical, 12)
    }
}

struct SecurityActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(AppColors.primary)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(.horizontal, AppConstants.screenPadding)
            .padding(.vertical, 12)
        }
    }
}

struct SecurityView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SecurityView(authVM: AuthViewModel())
        }
        .preferredColorScheme(.dark)
    }
}