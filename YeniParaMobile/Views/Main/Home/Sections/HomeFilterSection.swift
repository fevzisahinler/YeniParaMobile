import SwiftUI

struct HomeFilterSection: View {
    @Binding var selectedFilter: FilterType
    let getFilterCount: (FilterType) -> Int
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(FilterType.allCases, id: \.self) { filter in
                    FilterChip(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        count: getFilterCount(filter),
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFilter = filter
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}
