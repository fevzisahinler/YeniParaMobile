import SwiftUI

struct LoadingStockRow: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Logo placeholder
            ShimmerView(cornerRadius: 10)
                .frame(width: 44, height: 44)
            
            // Info placeholder
            VStack(alignment: .leading, spacing: 6) {
                ShimmerView(cornerRadius: 4)
                    .frame(width: 60, height: 14)
                
                ShimmerView(cornerRadius: 4)
                    .frame(width: 120, height: 10)
            }
            
            Spacer()
            
            // Price placeholder
            VStack(alignment: .trailing, spacing: 4) {
                ShimmerView(cornerRadius: 4)
                    .frame(width: 70, height: 14)
                
                ShimmerView(cornerRadius: 4)
                    .frame(width: 50, height: 12)
            }
            
            // Button placeholder
            ShimmerView(cornerRadius: 16)
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackground)
        )
    }
}

// MARK: - ShimmerView.swift (Helper)
struct ShimmerView: View {
    @State private var isAnimating = false
    let cornerRadius: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.white.opacity(0.1))
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.1),
                            Color.white.opacity(0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
                    .animation(
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                }
            )
            .clipped()
            .onAppear {
                isAnimating = true
            }
    }
}
