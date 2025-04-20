//
//  YeniParaMobileApp.swift
//  YeniParaMobile
//
//  Created by Fevzi Sahinler on 4/20/25.
//

import SwiftUI

@main
struct YeniParaMobileApp: App {
    @StateObject private var authVM = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(authVM: authVM)
        }
    }
}
