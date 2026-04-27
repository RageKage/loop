import EventKit
import MapKit
import SwiftData
import SwiftUI

// MARK: - EventDetailView

/// Full-screen detail sheet for a single event.
/// Handles RSVP toggling (SavedEvent), EventKit calendar export, and Apple Maps directions.
struct EventDetailView: View {
    let event: Event

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss
    @Query private var savedEvents: [SavedEvent]

    @State private var addedToCalendar  = false
    @State private var showCalendarAlert = false
    @State private var calendarAlertMessage = ""
    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    @State private var showReport = false

    // MARK: Computed

    private var savedEvent: SavedEvent? {
        savedEvents.first { $0.eventID == event.id }
    }

    private var savedStatus: SavedEventStatus? {
        savedEvent?.statusEnum
    }

    private var isOwner: Bool {
        guard let creatorID = event.creatorID,
              let userID = AuthService.shared.currentIdentity?.userID else { return false }
        return creatorID == userID
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    categoryHeader
                    if isOwner {
                        divider
                        ownerControls
                    }
                    divider
                    dateSection
                    divider
                    locationSection
                    if !event.eventDescription.isEmpty {
                        divider
                        descriptionSection
                    }
                    divider
                    rsvpSection
                    divider
                    actionSection
                    divider
                    reportSection
                    Spacer(minLength: 32)
                }
                .padding()
            }
            .navigationTitle(event.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    ShareLink(
                        item: shareText,
                        subject: Text(event.title),
                        message: Text("Check out this event on Loop")
                    ) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Button("Done") { dismiss() }
                }
            }
            .alert("Calendar", isPresented: $showCalendarAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(calendarAlertMessage)
            }
            .sheet(isPresented: $showEdit) {
                NavigationStack {
                    EditEventFormView(event: event, onSaved: { _ in })
                }
            }
            .sheet(isPresented: $showReport) {
                ReportEventSheet(event: event)
            }
            .confirmationDialog(
                "Delete this event?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { deleteEvent() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone.")
            }
        }
    }

    // MARK: Reusable divider

    private var divider: some View {
        Divider().padding(.vertical, 16)
    }

    // MARK: Subviews

    private var ownerControls: some View {
        HStack(spacing: 12) {
            Button { showEdit = true } label: {
                Label("Edit Event", systemImage: "pencil")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.blue)

            Button(role: .destructive) { showDeleteConfirm = true } label: {
                Label("Delete", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
    }

    private var categoryHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(event.categoryEnum.color.opacity(0.12))
                    .frame(width: 50, height: 50)
                Image(systemName: event.categoryEnum.systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(event.categoryEnum.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(event.categoryEnum.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(event.isFree ? "Free" : String(format: "$%.0f", event.price ?? 0))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(event.isFree ? Color.green : Color.primary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if EventTrustSignal.isVerified(event) {
                    Label("By \(event.organizerName)", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                } else {
                    Text("By \(event.organizerName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Community post")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .multilineTextAlignment(.trailing)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Date & Time", systemImage: "calendar")
                .font(.headline)
            Text(event.startDate.formatted(date: .long, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let end = event.endDate {
                Text("Ends \(end.formatted(date: .omitted, time: .shortened))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let rule = event.recurrenceRule,
               let display = rule.rruleDisplayString {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                    Text(display)
                        .font(.subheadline)
                }
                .foregroundStyle(.blue)
            }
        }
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Location", systemImage: "mappin.and.ellipse")
                .font(.headline)
            Text(event.locationName)
                .font(.subheadline)
                .fontWeight(.medium)
            if let address = event.address {
                Text(address)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            // Static mini-map
            Map(position: .constant(.region(MKCoordinateRegion(
                center: event.coordinate,
                latitudinalMeters: 600,
                longitudinalMeters: 600
            )))) {
                Marker(event.locationName, coordinate: event.coordinate)
                    .tint(event.categoryEnum.color)
            }
            .disabled(true)
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("About", systemImage: "text.alignleft")
                .font(.headline)
            Text(event.eventDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var rsvpSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Are you going?")
                .font(.headline)
            HStack(spacing: 12) {
                RSVPButton(
                    label: "I'm Going",
                    systemImage: "checkmark.circle.fill",
                    isActive: savedStatus == .going,
                    action: { toggleStatus(.going) }
                )
                RSVPButton(
                    label: "Interested",
                    systemImage: "star.fill",
                    isActive: savedStatus == .interested,
                    action: { toggleStatus(.interested) }
                )
            }
        }
    }

    private var actionSection: some View {
        VStack(spacing: 12) {
            Button {
                Task { await addToCalendar() }
            } label: {
                Label(
                    addedToCalendar ? "Added to Calendar" : "Add to Calendar",
                    systemImage: addedToCalendar ? "checkmark.circle.fill" : "calendar.badge.plus"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(addedToCalendar ? .green : .blue)
            .disabled(addedToCalendar)

            Button { openDirections() } label: {
                Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.blue)
        }
    }

    // MARK: Actions

    private var reportSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !isOwner {
                Button { showReport = true } label: {
                    Text("Report this event")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .underline()
                }
                .buttonStyle(.plain)
            }
            Text(EventTrustSignal.isVerified(event)
                ? "This event was posted by a verified organizer who can edit or remove it."
                : "This event was shared by a community member. Details may have changed since posting. Report if inaccurate.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Share text

    private var shareText: String {
        var lines: [String] = [event.title]

        // Date / time
        if let end = event.endDate {
            let dateStr   = event.startDate.formatted(date: .abbreviated, time: .omitted)
            let startTime = event.startDate.formatted(date: .omitted,     time: .shortened)
            let endTime   = end.formatted(          date: .omitted,       time: .shortened)
            lines.append("📅 \(dateStr) from \(startTime) to \(endTime)")
        } else {
            lines.append("📅 \(event.startDate.formatted(date: .abbreviated, time: .shortened))")
        }

        // Recurrence
        if let rule = event.recurrenceRule, let display = rule.rruleDisplayString {
            lines.append(display)
        }

        // Location
        lines.append("📍 \(event.locationName)")

        // Price
        if event.isFree {
            lines.append("✨ Free")
        } else if let price = event.price {
            lines.append("💵 $\(Int(price))")
        }

        // Description — omit entirely if empty
        let desc = event.eventDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !desc.isEmpty { lines.append(desc) }

        // TODO: deep link — add "https://loop.app/event/\(event.id)" when backend is live
        lines.append("Shared via Loop")

        return lines.joined(separator: "\n")
    }

    private func deleteEvent() {
        savedEvents.filter { $0.eventID == event.id }.forEach { modelContext.delete($0) }
        modelContext.delete(event)
        dismiss()
    }

    private func toggleStatus(_ status: SavedEventStatus) {
        if let existing = savedEvent {
            if existing.statusEnum == status {
                if status == .going {
                    NotificationService.shared.cancelRSVPReminder(for: event.id)
                }
                modelContext.delete(existing)
            } else {
                if existing.statusEnum == .going {
                    NotificationService.shared.cancelRSVPReminder(for: event.id)
                }
                existing.status = status.rawValue
                if status == .going {
                    NotificationService.shared.scheduleRSVPReminder(for: event)
                }
            }
        } else {
            modelContext.insert(SavedEvent(eventID: event.id, status: status.rawValue))
            if status == .going {
                NotificationService.shared.scheduleRSVPReminder(for: event)
            }
        }
    }

    private func addToCalendar() async {
        let store = EKEventStore()
        do {
            let granted = try await store.requestWriteOnlyAccessToEvents()
            guard granted else {
                calendarAlertMessage = "Calendar access was denied. Enable it in Settings → Privacy & Security → Calendars."
                showCalendarAlert = true
                return
            }
            let ekEvent = EKEvent(eventStore: store)
            ekEvent.title     = event.title
            ekEvent.startDate = event.startDate
            ekEvent.endDate   = event.endDate ?? event.startDate.addingTimeInterval(3_600)
            ekEvent.notes     = event.eventDescription
            ekEvent.location  = event.address ?? event.locationName
            ekEvent.calendar  = store.defaultCalendarForNewEvents
            try store.save(ekEvent, span: .thisEvent)
            addedToCalendar = true
        } catch {
            calendarAlertMessage = "Couldn't add to calendar: \(error.localizedDescription)"
            showCalendarAlert = true
        }
    }

    private func openDirections() {
        // iOS 26: MKPlacemark/init(placemark:) are deprecated.
        // New API: init(location:address:) — pass nil for address to skip structured data.
        let item = MKMapItem(location: event.clLocation, address: nil)
        item.name = event.locationName
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault
        ])
    }
}

// MARK: - RSVPButton

private struct RSVPButton: View {
    let label: String
    let systemImage: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: systemImage)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(isActive ? .blue : .gray)
        .animation(.snappy(duration: 0.15), value: isActive)
    }
}
