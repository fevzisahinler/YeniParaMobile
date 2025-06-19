import SwiftUI

struct SymbolDetailActions: View {
    let symbol: String
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                // Add to portfolio action
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Portföye Ekle")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColors.primary)
                .cornerRadius(12)
            }
            
            Button(action: {
                // Set price alert action
            }) {
                HStack {
                    Image(systemName: "bell")
                    Text("Fiyat Uyarısı Oluştur")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}
