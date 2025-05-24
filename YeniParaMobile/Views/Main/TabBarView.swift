// TabBarView.swift - Tab bar'ın tüm view'larda görünmesi için düzeltildi
import SwiftUI

struct TabBarView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var selectedTab: Int = 0
    
    init(authVM: AuthViewModel) {
        self.authVM = authVM
        
        // Tab bar görünümünü özelleştir
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 20/255, green: 21/255, blue: 26/255, alpha: 1.0)
        
        // Normal state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(white: 0.6, alpha: 1.0)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(white: 0.6, alpha: 1.0),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        // Selected state
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 143/255, green: 217/255, blue: 83/255, alpha: 1.0)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(red: 143/255, green: 217/255, blue: 83/255, alpha: 1.0),
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        
        // Border ve shadow
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.3)
        appearance.shadowImage = UIImage()
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(white: 0.6, alpha: 1.0)
        UITabBar.appearance().tintColor = UIColor(red: 143/255, green: 217/255, blue: 83/255, alpha: 1.0)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // 1. Anasayfa - Dashboard
            NavigationStack {
                DashboardView(authVM: authVM)
                    .navigationBarHidden(true)
            }
            .tabItem {
                VStack(spacing: 4) {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        .font(.system(size: 20, weight: selectedTab == 0 ? .semibold : .regular))
                    Text("Anasayfa")
                        .font(.system(size: 10, weight: selectedTab == 0 ? .semibold : .medium))
                }
            }
            .tag(0)

            // 2. Hisseler
            NavigationStack {
                HomeView(authVM: authVM)
                    .navigationBarHidden(true)
            }
            .tabItem {
                VStack(spacing: 4) {
                    Image(systemName: selectedTab == 1 ? "chart.line.uptrend.xyaxis.circle.fill" : "chart.line.uptrend.xyaxis")
                        .font(.system(size: 20, weight: selectedTab == 1 ? .semibold : .regular))
                    Text("Hisseler")
                        .font(.system(size: 10, weight: selectedTab == 1 ? .semibold : .medium))
                }
            }
            .tag(1)

            // 3. Topluluk
            NavigationStack {
                CommunityView(authVM: authVM)
                    .navigationBarHidden(true)
            }
            .tabItem {
                VStack(spacing: 4) {
                    Image(systemName: selectedTab == 2 ? "person.3.fill" : "person.3")
                        .font(.system(size: 20, weight: selectedTab == 2 ? .semibold : .regular))
                    Text("Topluluk")
                        .font(.system(size: 10, weight: selectedTab == 2 ? .semibold : .medium))
                }
            }
            .tag(2)

            // 4. Profil
            NavigationStack {
                ProfileView(authVM: authVM)
                    .navigationBarHidden(true)
            }
            .tabItem {
                VStack(spacing: 4) {
                    Image(systemName: selectedTab == 3 ? "person.crop.circle.fill" : "person.crop.circle")
                        .font(.system(size: 20, weight: selectedTab == 3 ? .semibold : .regular))
                    Text("Profil")
                        .font(.system(size: 10, weight: selectedTab == 3 ? .semibold : .medium))
                }
            }
            .tag(3)
        }
        .background(AppColors.background)
        .onAppear {
            // Tab bar shadow efekti
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 20/255, green: 21/255, blue: 26/255, alpha: 1.0)
            
            // Top border ekle
            let borderColor = UIColor(red: 40/255, green: 41/255, blue: 46/255, alpha: 1.0)
            appearance.shadowImage = createBorderImage(color: borderColor, height: 1.0)
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    private func createBorderImage(color: UIColor, height: CGFloat) -> UIImage {
        let size = CGSize(width: 1.0, height: height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView(authVM: AuthViewModel())
            .preferredColorScheme(.dark)
    }
}
