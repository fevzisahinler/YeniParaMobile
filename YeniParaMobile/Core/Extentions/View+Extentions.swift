import SwiftUI

// MARK: - View Extensions
extension View {
    // MARK: - Conditional Modifiers
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func ifLet<T, Transform: View>(_ optional: T?, transform: (Self, T) -> Transform) -> some View {
        if let value = optional {
            transform(self, value)
        } else {
            self
        }
    }
    
    // MARK: - Loading Overlay
    func loadingOverlay(_ isLoading: Bool) -> some View {
        self.overlay(
            Group {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                            .scaleEffect(1.2)
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppColors.cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppColors.cardBorder, lineWidth: 1)
                                    )
                            )
                    }
                    .transition(.opacity)
                }
            }
        )
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
    
    // MARK: - Error Alert
    func errorAlert(isPresented: Binding<Bool>, error: String) -> some View {
        self.alert("Hata", isPresented: isPresented) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(error)
        }
    }
    
    // MARK: - Keyboard Dismissal
    func hideKeyboard() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    // MARK: - Card Style
    func cardStyle(padding: CGFloat = 16, cornerRadius: CGFloat = 12) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(AppColors.cardBorder, lineWidth: 1)
                    )
            )
    }
    
    // MARK: - Shimmer Effect
    func shimmer(isAnimating: Bool) -> some View {
        self.modifier(ShimmerModifier(isAnimating: isAnimating))
    }
    
    // MARK: - Navigation Bar Styling
    func navigationBarStyle(backgroundColor: Color = AppColors.background, titleColor: Color = AppColors.textPrimary) -> some View {
        self
            .toolbarBackground(backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    // MARK: - Corner Radius with Border
    func cornerRadiusWithBorder(radius: CGFloat, borderColor: Color, lineWidth: CGFloat = 1) -> some View {
        self
            .cornerRadius(radius)
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(borderColor, lineWidth: lineWidth)
            )
    }
    
    // MARK: - Glow Effect
    func glowEffect(color: Color, radius: CGFloat = 10) -> some View {
        self
            .shadow(color: color.opacity(0.6), radius: radius)
            .shadow(color: color.opacity(0.3), radius: radius * 2)
    }
    
    // MARK: - Parallax Effect
    func parallaxEffect(minHeight: CGFloat = 0, idealHeight: CGFloat = 300, maxHeight: CGFloat = 500) -> some View {
        self.frame(minHeight: minHeight, idealHeight: idealHeight, maxHeight: maxHeight)
            .clipped()
    }
    
    // MARK: - Read Size
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometry.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
    
    // MARK: - Animated Gradient Background
    func animatedGradientBackground(colors: [Color], animation: Animation = .linear(duration: 3).repeatForever(autoreverses: true)) -> some View {
        self.background(
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .hueRotation(.degrees(0))
                .animation(animation, value: UUID())
        )
    }
}

// MARK: - Size Preference Key
struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

// MARK: - Shimmer Modifier
struct ShimmerModifier: ViewModifier {
    let isAnimating: Bool
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if isAnimating {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                        .animation(
                            Animation.linear(duration: 1.5)
                                .repeatForever(autoreverses: false),
                            value: phase
                        )
                        .onAppear {
                            phase = 1
                        }
                    }
                }
            )
            .clipped()
    }
}

// MARK: - Redacted Modifier
extension View {
    @ViewBuilder
    func redactedShimmer(_ isLoading: Bool) -> some View {
        if isLoading {
            self
                .redacted(reason: .placeholder)
                .shimmer(isAnimating: true)
        } else {
            self
        }
    }
}

// MARK: - Safe Area Extensions
extension View {
    var safeAreaTop: CGFloat {
        UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
    }
    
    var safeAreaBottom: CGFloat {
        UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
    }
}

// MARK: - Haptic Feedback
extension View {
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: style)
            impactFeedback.impactOccurred()
        }
    }
}

// MARK: - Animated Appearance
extension View {
    func animateAppearance(delay: Double = 0, duration: Double = 0.3) -> some View {
        self
            .opacity(0)
            .onAppear {
                withAnimation(.easeOut(duration: duration).delay(delay)) {
                    self.opacity(1)
                }
            }
    }
}
