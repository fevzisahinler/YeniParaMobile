import SwiftUI

struct TabBarView: View {
    @ObservedObject var authVM: AuthViewModel
    @StateObject private var navigationManager = NavigationManager()
    @State private var selectedTab: Int = 0
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Main content area
                TabView(selection: $selectedTab) {
                    DashboardView(authVM: authVM)
                        .tag(0)
                    
                    HomeView(authVM: authVM)
                        .tag(1)
                    
                    CommunityView(authVM: authVM)
                        .tag(2)
                    
                    ProfileView(authVM: authVM)
                        .tag(3)
                }
                .tabViewStyle(DefaultTabViewStyle())
                .ignoresSafeArea(.all)
                .environmentObject(authVM)  // Added this line - ÖNEMLİ
                .environmentObject(navigationManager)
                
                // Custom Tab Bar
                CustomTabBar(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(.all)
            .navigationBarHidden(true)
        }
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    private func setupTabBarAppearance() {
        UITabBar.appearance().isHidden = true
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ForEach(TabBarItem.allCases, id: \.rawValue) { item in
                TabBarButton(
                    item: item,
                    isSelected: selectedTab == item.rawValue
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectTab(item.rawValue)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 20)
        .background(
            TabBarBackground()
        )
        .ignoresSafeArea(.all, edges: .bottom)
    }
    
    private func selectTab(_ tab: Int) {
        if selectedTab != tab {
            selectedTab = tab
            impactFeedback.impactOccurred()
        }
    }
}

struct TabBarBackground: View {
    var body: some View {
        ZStack {
            // Main background with subtle gradient
            LinearGradient(
                colors: [
                    AppColors.cardBackground,
                    AppColors.cardBackground.opacity(0.98)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Blur effect overlay
            VisualEffectBlur(blurStyle: .systemChromeMaterialDark)
                .opacity(0.9)
            
            // Top border
            VStack {
                Rectangle()
                    .fill(AppColors.cardBorder.opacity(0.3))
                    .frame(height: 0.5)
                Spacer()
            }
        }
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: -2)
    }
}

struct VisualEffectBlur: UIViewRepresentable {
    let blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct TabBarButton: View {
    let item: TabBarItem
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Icon
                Image(systemName: isSelected ? item.selectedIcon : item.icon)
                    .font(.system(size: isSelected ? 24 : 22, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isPressed)
                    .frame(height: 32)
                
                // Label
                Text(item.title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .contentShape(Rectangle())  // Make entire area tappable
        }
        .buttonStyle(ScaleButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// Custom button style for better tap feedback
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

enum TabBarItem: Int, CaseIterable {
    case dashboard = 0
    case stocks = 1
    case community = 2
    case profile = 3
    
    var title: String {
        switch self {
        case .dashboard: return "Anasayfa"
        case .stocks: return "Hisseler"
        case .community: return "Topluluk"
        case .profile: return "Profil"
        }
    }
    
    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .stocks: return "chart.line.uptrend.xyaxis"
        case .community: return "bubble.left.and.bubble.right"
        case .profile: return "person"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .stocks: return "chart.line.uptrend.xyaxis"
        case .community: return "bubble.left.and.bubble.right.fill"
        case .profile: return "person.fill"
        }
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView(authVM: AuthViewModel())
            .preferredColorScheme(.dark)
    }
}
