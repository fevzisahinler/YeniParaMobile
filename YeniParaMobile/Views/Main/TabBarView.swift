import SwiftUI

struct TabBarView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var selectedTab: Int = 0
    
    var body: some View {
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
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .ignoresSafeArea(.all)
            .environmentObject(authVM)  // Added this line - ÖNEMLİ
            
            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.all)
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
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ForEach(TabBarItem.allCases, id: \.rawValue) { item in
                TabBarButton(
                    item: item,
                    isSelected: selectedTab == item.rawValue
                ) {
                    selectTab(item.rawValue)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(
            TabBarBackground()
        )
        .ignoresSafeArea(.all, edges: .bottom)
    }
    
    private func selectTab(_ tab: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedTab = tab
        }
        impactFeedback.impactOccurred()
    }
}

struct TabBarBackground: View {
    var body: some View {
        ZStack {
            // Main background
            AppColors.cardBackground
            
            // Blur effect overlay
            VisualEffectBlur(blurStyle: .systemThinMaterialDark)
                .opacity(0.95)
            
            // Top border with gradient
            VStack {
                LinearGradient(
                    colors: [
                        AppColors.primary.opacity(0.3),
                        AppColors.primary.opacity(0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 1)
                Spacer()
            }
        }
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: -5)
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
            VStack(spacing: 6) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.primary.opacity(0.2), AppColors.primary.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .blur(radius: 4)
                    }
                    
                    Image(systemName: isSelected ? item.selectedIcon : item.icon)
                        .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)
                        .symbolEffect(.bounce, value: isSelected)
                }
                .frame(height: 28)
                
                Text(item.title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
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
        case .dashboard: return "house"
        case .stocks: return "chart.line.uptrend.xyaxis"
        case .community: return "person.3"
        case .profile: return "person.crop.circle"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .stocks: return "chart.line.uptrend.xyaxis"
        case .community: return "person.3.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView(authVM: AuthViewModel())
            .preferredColorScheme(.dark)
    }
}
