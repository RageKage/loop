import SwiftData
import SwiftUI

/// Root view. Owns the three-tab shell; each tab owns its own NavigationStack.
struct ContentView: View {
    @AppStorage("selectedTab") private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Discover", systemImage: "map", value: 0) {
                DiscoverView()
            }
            Tab("Create", systemImage: "plus.circle.fill", value: 1) {
                CreateView()
            }
            Tab("You", systemImage: "person.crop.circle.fill", value: 2) {
                YouView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Event.self, SavedEvent.self], inMemory: true)
}
