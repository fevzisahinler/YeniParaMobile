import SwiftUI

struct BackButton: View {
    let action: () -> Void
    var title: String = "Geri"
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.white)
        }
    }
}
