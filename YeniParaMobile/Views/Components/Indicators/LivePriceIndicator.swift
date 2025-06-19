import SwiftUI

struct LivePriceIndicator: View {
    let isAnimating: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.green)
                .frame(width: 6, height: 6)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .animation(
                    .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            Text("Canlı Fiyatlar")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
        }
    }
}
