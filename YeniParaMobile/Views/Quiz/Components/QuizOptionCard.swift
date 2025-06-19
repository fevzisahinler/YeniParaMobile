import SwiftUI

struct QuizOptionCard: View {
    let option: QuizOption
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Selection indicator with animation
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? AppColors.primary : Color.white.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 12, height: 12)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                
                // Option text
                Text(option.optionText)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.9))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                        AppColors.primary.opacity(0.15) :
                        Color.white.opacity(0.08)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? AppColors.primary : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
    }
}