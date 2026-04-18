import SwiftUI

/// Phase 1 placeholder. Phase 2 will replace this with a MapKit map + list toggle
/// showing nearby events pulled from the public CloudKit database.
struct DiscoverView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("No Events Yet", systemImage: "map")
            } description: {
                Text("Nearby community events will appear here.\nMap and list view coming in Phase 2.")
            }
            .navigationTitle("Discover")
        }
    }
}

#Preview {
    DiscoverView()
}
