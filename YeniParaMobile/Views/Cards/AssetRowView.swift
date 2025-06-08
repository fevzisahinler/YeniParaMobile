import SwiftUI

struct AssetRowView: View {
    let asset: Asset

    var body: some View {
        HStack(spacing: 12) {
            // Stock Info
            HStack(spacing: 12) {
                // Stock Icon
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(asset.symbol.prefix(2)))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.textPrimary)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(asset.symbol)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(asset.companyName)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Price Info
            VStack(alignment: .trailing, spacing: 2) {
                Text(asset.formattedPrice)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Vol: \(asset.volume)")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(width: 80)
            
            // Change Info
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: asset.changePercent >= 0 ? "triangle.fill" : "triangle.fill")
                        .font(.caption2)
                        .rotationEffect(.degrees(asset.changePercent >= 0 ? 0 : 180))
                        .foregroundColor(asset.changeColor)
                    
                    Text(asset.formattedChangePercent)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(asset.changeColor)
                }
                
                Text(asset.formattedChange)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(width: 80)
        }
        .contentShape(Rectangle())
    }
}

struct AssetRowView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleAsset = Asset(
            symbol: "AAPL",
            companyName: "Apple Inc.",
            price: 175.23,
            change: 4.12,
            changePercent: 2.45,
            volume: "45.2M",
            marketCap: "2.8T",
            high24h: 178.45,
            low24h: 172.10
        )
        
        AssetRowView(asset: sampleAsset)
            .padding()
            .background(Color(red: 28/255, green: 29/255, blue: 36/255))
            .preferredColorScheme(.dark)
            .previewLayout(.sizeThatFits)
    }
}
