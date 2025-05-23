// File: YeniParaMobile/Views/TabBarView.swift

import SwiftUI

struct TabBarView: View {
    @ObservedObject var authVM: AuthViewModel

    var body: some View {
        TabView {
            // 1. Anasayfa
            NavigationStack {
                Text("Anasayfa İçeriği")
                    .font(.title)
                    .foregroundColor(.secondary)
                    .navigationTitle("Anasayfa")
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Anasayfa")
            }

            // 2. Hisseler (mevcut HomeView)
            NavigationStack {
                HomeView(authVM: authVM)
                    .navigationTitle("Hisseler")
            }
            .tabItem {
                Image(systemName: "chart.line.uptrend.xyaxis")
                Text("Hisseler")
            }

            // 3. Topluluk
            NavigationStack {
                Text("Topluluk İçeriği")
                    .font(.title)
                    .foregroundColor(.secondary)
                    .navigationTitle("Topluluk")
            }
            .tabItem {
                Image(systemName: "person.3.fill")
                Text("Topluluk")
            }

            // 4. Profil
            NavigationStack {
                Text("Profil İçeriği")
                    .font(.title)
                    .foregroundColor(.secondary)
                    .navigationTitle("Profil")
            }
            .tabItem {
                Image(systemName: "person.crop.circle")
                Text("Profil")
            }
        }
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView(authVM: AuthViewModel())
    }
}
