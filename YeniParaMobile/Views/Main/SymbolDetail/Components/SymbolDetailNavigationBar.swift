// Views/Main/SymbolDetail/Components/SymbolDetailNavigationBar.swift
import SwiftUI

struct SymbolDetailNavigationBar: View {
    let symbol: String
    let isInWatchlist: Bool
    let onBack: () -> Void
    let onToggleWatchlist: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 40, height: 40)
            }
            
            Spacer()
            
            Text(symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: onToggleWatchlist) {
                    Image(systemName: isInWatchlist ? "heart.fill" : "heart")
                        .font(.system(size: 18))
                        .foregroundColor(isInWatchlist ? AppColors.error : AppColors.textPrimary)
                        .frame(width: 40, height: 40)
                }
                
                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 40, height: 40)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AppColors.background)
    }
}
