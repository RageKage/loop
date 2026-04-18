import SwiftUI

// MARK: - FilterChip

/// A toggleable pill-shaped chip used in the filter bar.
private struct FilterChip: View {
    let label: String
    let systemImage: String?
    @Binding var isActive: Bool

    init(_ label: String, systemImage: String? = nil, isActive: Binding<Bool>) {
        self.label = label
        self.systemImage = systemImage
        self._isActive = isActive
    }

    var body: some View {
        Button { isActive.toggle() } label: {
            HStack(spacing: 4) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.caption)
                }
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isActive ? Color.accentColor : Color(.systemGray6))
            .foregroundStyle(isActive ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.snappy(duration: 0.15), value: isActive)
    }
}

// MARK: - FilterBarView

/// Horizontal scrolling row of filter chips for the Discover tab.
/// "Today" and "This Week" are mutually exclusive — toggling one clears the other.
struct FilterBarView: View {
    @Bindable var viewModel: DiscoverViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {

                FilterChip("Free", systemImage: "tag", isActive: $viewModel.showFreeOnly)

                FilterChip("Today", isActive: Binding(
                    get: { viewModel.showToday },
                    set: { if $0 { viewModel.showThisWeek = false }; viewModel.showToday = $0 }
                ))

                FilterChip("This Week", isActive: Binding(
                    get: { viewModel.showThisWeek },
                    set: { if $0 { viewModel.showToday = false }; viewModel.showThisWeek = $0 }
                ))

                Divider().frame(height: 20)

                ForEach(EventCategory.allCases, id: \.self) { category in
                    FilterChip(
                        category.displayName,
                        systemImage: category.systemImage,
                        isActive: Binding(
                            get: { viewModel.selectedCategories.contains(category) },
                            set: { active in
                                if active {
                                    viewModel.selectedCategories.insert(category)
                                } else {
                                    viewModel.selectedCategories.remove(category)
                                }
                            }
                        )
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }
}
