//
//  ContentView.swift
//  YeniParaMobile
//
//  Created by Fevzi Sahinler on 4/20/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var authVM: AuthViewModel

    var body: some View {
        WelcomeView(authVM: authVM)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(authVM: AuthViewModel())
    }
}
