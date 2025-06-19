import SwiftUI

struct HomeHeaderSection: View {
    let favoriteStocks: Set<String>
    let isLoading: Bool
    let onFavoritesAction: () -> Void
    let onRefreshAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hisse Senetleri")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        
                        Text("Canlı Fiyatlar")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Favorites Button
                    Button(action: onFavoritesAction) {
                        ZStack {
                            Circle()
                                .fill(AppColors.cardBackground)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(AppColors.cardBorder, lineWidth: 1)
                                )
                            
                            Image(systemName: "heart.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(AppColors.primary)
                            
                            if !favoriteStocks.isEmpty {
                                Text("\(favoriteStocks.count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(minWidth: 16, minHeight: 16)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 14, y: -14)
                            }
                        }
                    }
                    
                    // Refresh Button
                    Button(action: onRefreshAction) {
                        Circle()
                            .fill(AppColors.cardBackground)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(AppColors.cardBorder, lineWidth: 1)
                            )
                            .overlay(
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                                    .rotationEffect(.degrees(isLoading ? 360 : 0))
                                    .animation(
                                        isLoading ?
                                        .linear(duration: 1).repeatForever(autoreverses: false) :
                                        .default,
                                        value: isLoading
                                    )
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(AppColors.background)
    }
}
