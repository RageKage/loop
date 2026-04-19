import CoreLocation
import GoogleSignIn
import SwiftData
import SwiftUI

struct MyEventsView: View {
    @Query private var allEvents: [Event]
    @Query private var savedEvents: [SavedEvent]

    @State private var selectedTab: MyEventsTab = .going
    @State private var selectedEvent: Event? = nil
    @State private var locationService = LocationService()

    private var identity: AuthIdentity? { AuthService.shared.currentIdentity }

    // MARK: - Filtered lists

    private var goingEvents: [Event] {
        let ids = Set(savedEvents.filter { $0.status == SavedEventStatus.going.rawValue }.map(\.eventID))
        return allEvents.filter { ids.contains($0.id) }
    }

    private var interestedEvents: [Event] {
        let ids = Set(savedEvents.filter { $0.status == SavedEventStatus.interested.rawValue }.map(\.eventID))
        return allEvents.filter { ids.contains($0.id) }
    }

    private var hostingEvents: [Event] {
        guard let userID = identity?.userID else { return [] }
        return allEvents.filter { $0.creatorID == userID }
    }

    private var currentEvents: [Event] {
        switch selectedTab {
        case .going:      return goingEvents
        case .interested: return interestedEvents
        case .hosting:    return hostingEvents
        }
    }

    private var upcoming: [Event] {
        currentEvents.filter { $0.startDate >= .now }.sorted { $0.startDate < $1.startDate }
    }

    private var past: [Event] {
        currentEvents.filter { $0.startDate < .now }.sorted { $0.startDate > $1.startDate }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Tab", selection: $selectedTab) {
                    ForEach(MyEventsTab.allCases) { tab in
                        Text(tab.displayName).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)

                Group {
                    if selectedTab == .hosting && identity == nil {
                        signedOutHostingState
                    } else if upcoming.isEmpty && past.isEmpty {
                        emptyState(for: selectedTab)
                    } else {
                        eventList
                    }
                }
                .animation(.default, value: selectedTab)
            }
            .navigationTitle("My Events")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedEvent) { event in
                EventDetailView(event: event)
            }
        }
    }

    // MARK: - Event list

    private var eventList: some View {
        List {
            if !upcoming.isEmpty {
                Section("Upcoming") {
                    ForEach(upcoming) { event in
                        Button { selectedEvent = event } label: {
                            EventListRowView(event: event, userLocation: locationService.effectiveLocation)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            if !past.isEmpty {
                Section("Past") {
                    ForEach(past) { event in
                        Button { selectedEvent = event } label: {
                            EventListRowView(event: event, userLocation: locationService.effectiveLocation)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty states

    @ViewBuilder
    private func emptyState(for tab: MyEventsTab) -> some View {
        Spacer()
        VStack(spacing: 16) {
            Image(systemName: tab.emptyIcon)
                .font(.system(size: 48))
                .foregroundStyle(.quaternary)
            VStack(spacing: 6) {
                Text(tab.emptyTitle)
                    .font(.headline)
                Text(tab.emptySubtitle(signedIn: identity != nil))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        Spacer()
    }

    private var signedOutHostingState: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.quaternary)
            VStack(spacing: 6) {
                Text("Sign in to see events you host")
                    .font(.headline)
                Text("Events you publish appear here when you're signed in.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            SignInWithGoogleView(onSuccess: { _ in }, onError: { _ in })
                .padding(.horizontal, 48)
            Spacer()
        }
    }
}

// MARK: - MyEventsTab

enum MyEventsTab: String, CaseIterable, Identifiable {
    case going, interested, hosting

    var id: Self { self }

    var displayName: String {
        switch self {
        case .going:      "Going"
        case .interested: "Interested"
        case .hosting:    "Hosting"
        }
    }

    var emptyIcon: String {
        switch self {
        case .going:      "calendar"
        case .interested: "star"
        case .hosting:    "megaphone"
        }
    }

    var emptyTitle: String {
        switch self {
        case .going:      "No events you're going to yet"
        case .interested: "Nothing saved as interested"
        case .hosting:    "You haven't hosted an event yet"
        }
    }

    func emptySubtitle(signedIn: Bool) -> String {
        switch self {
        case .going:
            return "Tap I'm Going on an event in Discover to save it here."
        case .interested:
            return "Tap Interested on events you want to remember."
        case .hosting:
            return "Publish an event from the Create tab to see it here."
        }
    }
}
