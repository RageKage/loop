import SwiftData
import SwiftUI

/// Root view. Owns the four-tab shell; each tab owns its own NavigationStack.
struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Discover", systemImage: "map") {
                DiscoverView()
            }
            Tab("Create", systemImage: "plus.circle.fill") {
                CreateView()
            }
            Tab("My Events", systemImage: "bookmark") {
                MyEventsView()
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Event.self, SavedEvent.self], inMemory: true)
}
