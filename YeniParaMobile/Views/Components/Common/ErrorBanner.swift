import SwiftUI

struct ErrorBanner: View {
    let message: String
    let onRetry: (() -> Void)?
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                if let onRetry = onRetry {
                    Button("Yeniden Dene") {
                        onRetry()
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .cornerRadius(6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.error)
            
            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
