import SwiftUI

struct StockInfo: View {
    let stock: UISymbol
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Text(stock.code)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                MatchScoreBadge(score: calculateMatchScore())
            }
            
            Text(stock.name)
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
        }
    }
    
    private func calculateMatchScore() -> Int {
        // Implement calculation
        return Int.random(in: 40...95)
    }
}
