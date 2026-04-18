import SwiftData
import SwiftUI

/// Root of the Create tab.
/// Hosts a NavigationStack (so CreateEntryView → CreateEventFormView can push),
/// and owns the success toast that appears after a form publish.
struct CreateView: View {
    @State private var toastMessage: String? = nil

    var body: some View {
        NavigationStack {
            CreateEntryView { publishedTitle in
                withAnimation {
                    toastMessage = "\"\(publishedTitle)\" is live in Discover"
                }
            }
        }
        .toast($toastMessage)
    }
}

#Preview {
    CreateView()
        .modelContainer(for: [Event.self, SavedEvent.self], inMemory: true)
}
