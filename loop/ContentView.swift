import SwiftData
import SwiftUI

/// Root view. Owns the four-tab shell; each tab owns its own NavigationStack.
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
            Tab("My Events", systemImage: "bookmark", value: 2) {
                MyEventsView()
            }
            Tab("Settings", systemImage: "gearshape", value: 3) {
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Event.self, SavedEvent.self], inMemory: true)
}
