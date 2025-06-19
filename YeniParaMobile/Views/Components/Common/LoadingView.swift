import SwiftUI

struct LoadingView: View {
    let message: String
    
    init(message: String = "Yükleniyor...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                .scaleEffect(1.2)
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
