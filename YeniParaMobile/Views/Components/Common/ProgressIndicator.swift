import SwiftUI

struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < currentStep ? AppColors.primary : Color.white.opacity(0.3))
                    .frame(width: 24, height: 4)
            }
        }
    }
}
