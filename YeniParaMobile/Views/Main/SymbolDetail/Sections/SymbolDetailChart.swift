// Views/Main/SymbolDetail/Sections/SymbolDetailChart.swift
import SwiftUI

struct SymbolDetailChart: View {
    @ObservedObject var viewModel: SymbolDetailViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Timeframe selector
            HStack(spacing: 0) {
                ForEach(SymbolDetailViewModel.Timeframe.allCases, id: \.self) { timeframe in
                    Button(action: {
                        viewModel.changeTimeframe(timeframe)
                    }) {
                        Text(timeframe.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(viewModel.selectedTimeframe == timeframe ? .black : AppColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.selectedTimeframe == timeframe ?
                                AppColors.primary : Color.clear
                            )
                    }
                }
            }
            .background(AppColors.cardBackground)
            .cornerRadius(8)
            .padding(.horizontal, 20)
            
            // Chart placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackground)
                .frame(height: 300)
                .overlay(
                    Text("Grafik Alanı")
                        .foregroundColor(AppColors.textSecondary)
                )
                .padding(.horizontal, 20)
        }
    }
}
