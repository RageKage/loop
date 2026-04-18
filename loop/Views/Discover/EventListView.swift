import CoreLocation
import SwiftUI

struct EventListView: View {
    let events: [Event]
    let userLocation: CLLocation
    @Binding var selectedEvent: Event?

    var body: some View {
        if events.isEmpty {
            ContentUnavailableView(
                "No Events Found",
                systemImage: "calendar.badge.minus",
                description: Text("Try adjusting your filters, or check back later.")
            )
        } else {
            List(events) { event in
                EventListRowView(event: event, userLocation: userLocation)
                    .contentShape(Rectangle())
                    .onTapGesture { selectedEvent = event }
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
        }
    }
}
