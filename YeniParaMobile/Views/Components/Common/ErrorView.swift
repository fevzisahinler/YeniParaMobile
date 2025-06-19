import SwiftUI

struct ErrorView: View {
    let message: String
    let onRetry: (() -> Void)?
    
    init(message: String, onRetry: (() -> Void)? = nil) {
        self.message = message
        self.onRetry = onRetry
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Bir hata oluştu")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if let onRetry = onRetry {
                Button("Tekrar Dene", action: onRetry)
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppColors.primary)
                    .cornerRadius(AppConstants.cornerRadius)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
