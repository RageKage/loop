import SwiftData
import SwiftUI

/// Root of the Create tab.
/// Hosts a NavigationStack (so CreateEntryView → CreateEventFormView can push),
/// owns the success toast, and shows the pending-scans banner when relevant.
struct CreateView: View {
    @State private var toastMessage:        String? = nil
    @State private var showPendingScans     = false
    @State private var networkMonitor       = NetworkMonitor()

    @Query(sort: \PendingScan.createdAt) private var pendingScans: [PendingScan]

    private var showBanner: Bool {
        networkMonitor.isConnected && !pendingScans.isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showBanner {
                    PendingScansBanner(count: pendingScans.count) {
                        showPendingScans = true
                    }
                    Divider()
                }

                CreateEntryView { publishedTitle in
                    withAnimation {
                        toastMessage = "\"\(publishedTitle)\" is live in Discover"
                    }
                }
            }
        }
        .toast($toastMessage)
        .sheet(isPresented: $showPendingScans) {
            PendingScansView { publishedTitle in
                showPendingScans = false
                withAnimation {
                    toastMessage = "\"\(publishedTitle)\" is live in Discover"
                }
            }
        }
    }
}

#Preview {
    CreateView()
        .modelContainer(for: [Event.self, SavedEvent.self, PendingScan.self], inMemory: true)
}
