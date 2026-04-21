import CoreLocation
import SwiftUI

struct EventListView: View {
    let events: [Event]
    let userLocation: CLLocation
    @Binding var selectedEvent: Event?
    let shouldGroup: Bool

    var body: some View {
        List {
            if shouldGroup {
                ForEach(dateBuckets, id: \.label) { bucket in
                    Section(bucket.label) {
                        ForEach(bucket.events) { event in
                            row(for: event)
                        }
                    }
                }
            } else {
                ForEach(events) { event in
                    row(for: event)
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            // Muscle-memory gesture for now; @Query is reactive so no explicit refetch
            // needed until CloudKit sync lands in Phase 4c.
            try? await Task.sleep(for: .milliseconds(300))
        }
    }

    @ViewBuilder
    private func row(for event: Event) -> some View {
        EventListRowView(event: event, userLocation: userLocation)
            .contentShape(Rectangle())
            .onTapGesture { selectedEvent = event }
            .listRowSeparator(.hidden)
    }

    // MARK: - Date bucketing

    private struct DateBucket {
        let label: String
        let events: [Event]
    }

    private var dateBuckets: [DateBucket] {
        let cal = Calendar.current
        let now = Date.now
        guard let weekEnd = cal.date(byAdding: .day, value: 7, to: now) else { return [] }

        var today:    [Event] = []
        var tomorrow: [Event] = []
        var thisWeek: [Event] = []
        var later:    [Event] = []

        for event in events {
            if cal.isDateInToday(event.startDate) {
                today.append(event)
            } else if cal.isDateInTomorrow(event.startDate) {
                tomorrow.append(event)
            } else if event.startDate > now && event.startDate <= weekEnd {
                thisWeek.append(event)
            } else {
                later.append(event)
            }
        }

        var result: [DateBucket] = []
        if !today.isEmpty    { result.append(DateBucket(label: "Today",     events: today)) }
        if !tomorrow.isEmpty { result.append(DateBucket(label: "Tomorrow",  events: tomorrow)) }
        if !thisWeek.isEmpty { result.append(DateBucket(label: "This Week", events: thisWeek)) }
        if !later.isEmpty    { result.append(DateBucket(label: "Later",     events: later)) }
        return result
    }
}
