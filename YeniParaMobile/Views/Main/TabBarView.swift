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
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    private let greenColor = Color(red: 0.56, green: 0.85, blue: 0.32)
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ForEach(TabBarItem.allCases, id: \.rawValue) { item in
                TabBarButton(
                    item: item,
                    isSelected: selectedTab == item.rawValue,
                    greenColor: greenColor
                ) {
                    selectTab(item.rawValue)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 13)
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
            // Main background with blur effect
            VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
            
            // Subtle overlay
            Color.black.opacity(0.2)
            
            // Top separator line
            VStack {
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 0.5)
                Spacer()
            }
        }
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
    let greenColor: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Icon - always same, no change
                Image(systemName: item.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? greenColor : Color.white.opacity(0.6))
                    .frame(height: 24)
                
                // Label
                Text(item.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? greenColor : Color.white.opacity(0.6))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(isPressed ? 0.95 : 1.0)
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
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
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
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView(authVM: AuthViewModel())
            .preferredColorScheme(.dark)
    }
}
