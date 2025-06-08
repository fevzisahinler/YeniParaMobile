import SwiftUI

struct LogoView: View {
    var body: some View {
        Image(systemName: "chart.bar.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 60, height: 60)
            .foregroundColor(.green)
    }
}
