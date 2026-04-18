import SwiftUI

/// Phase 1 placeholder. Phase 3 will replace this with the full create-event flow:
///   - "Snap Poster" → AI extraction via Vision + Claude
///   - "Manual Entry" → form with title, date, recurrence, location, category, price
struct CreateView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Create an Event", systemImage: "plus.circle")
            } description: {
                Text("Snap a poster or fill in the details manually.\nEvent creation form coming in Phase 3.")
            }
            .navigationTitle("Create")
        }
    }
}

#Preview {
    CreateView()
}
