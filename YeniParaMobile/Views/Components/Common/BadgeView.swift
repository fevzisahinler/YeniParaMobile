import SwiftUI

struct BadgeView: View {
    let count: Int
    
    var body: some View {
        Text("\(count)")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .frame(minWidth: 16, minHeight: 16)
            .background(AppColors.error)
            .clipShape(Circle())
    }
}
