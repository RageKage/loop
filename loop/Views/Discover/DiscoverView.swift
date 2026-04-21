import SwiftData
import SwiftUI

/// The Discover tab: map or list of nearby approved events,
/// filterable by category, free/paid, and date range.
struct DiscoverView: View {

    // Only show events that have passed moderation.
    @Query(
        filter: #Predicate<Event> { $0.isApproved },
        sort: \.startDate
    )
    private var events: [Event]

    @State private var locationService = LocationService()
    @State private var viewModel       = DiscoverViewModel()
    @State private var selectedEvent: Event?

    // Shared with ContentView via UserDefaults so we can switch tabs from empty state.
    @AppStorage("selectedTab") private var selectedTab = 0

    // Apply filters + sort on every render; cheap for the event counts we expect.
    private var displayedEvents: [Event] {
        viewModel.filtered(events, near: locationService.effectiveLocation)
    }

    // MARK: - Empty States

    /// Zero events with no active filters — fresh install or cleared data.
    private var noEventsEmptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "map")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No events nearby yet")
                .font(.headline)
            Text("Be the first to post one! Events you or others create will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Create an Event") {
                selectedTab = 1
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
    }

    /// Search query is active but no events match.
    private var searchEmptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No events match \"\(viewModel.searchText)\"")
                .font(.headline)
            Text("Try a different search or clear filters.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Clear Search") {
                viewModel.searchText = ""
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding()
    }

    /// Filter chips are active but no events survive the filter pass.
    private var filterEmptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No events match your filters")
                .font(.headline)
            Text("Try removing some filters or check back later.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Clear Filters") {
                viewModel.showFreeOnly = false
                viewModel.showToday = false
                viewModel.showThisWeek = false
                viewModel.selectedCategories = []
                viewModel.searchText = ""
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // ── Filter chips ─────────────────────────────────────────────
                FilterBarView(viewModel: viewModel)
                    .padding(.top, 4)
                    .padding(.bottom, 4)

                Divider()

                // ── Content ──────────────────────────────────────────────────
                Group {
                    switch viewModel.displayMode {
                    case .map:
                        EventMapView(
                            events: displayedEvents,
                            selectedEvent: $selectedEvent,
                            userLocation: locationService.effectiveLocation,
                            isGloballyEmpty: displayedEvents.isEmpty && !viewModel.hasActiveFilters,
                            onSwitchToCreate: { selectedTab = 1 }
                        )
                    case .list:
                        if displayedEvents.isEmpty && !viewModel.hasActiveFilters {
                            noEventsEmptyState
                        } else if displayedEvents.isEmpty
                            && !viewModel.searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                            searchEmptyState
                        } else if displayedEvents.isEmpty {
                            filterEmptyState
                        } else {
                            EventListView(
                                events: displayedEvents,
                                userLocation: locationService.effectiveLocation,
                                selectedEvent: $selectedEvent,
                                shouldGroup: viewModel.shouldGroupByDate
                            )
                        }
                    }
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Map / List picker lives in the nav bar centre — reclaims all the
                // vertical space that the large title would otherwise consume.
                ToolbarItem(placement: .principal) {
                    Picker("View", selection: $viewModel.displayMode) {
                        Text("Map").tag(DiscoverViewModel.DisplayMode.map)
                        Text("List").tag(DiscoverViewModel.DisplayMode.list)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
            }
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search events, venues, organizers"
            )
            // Present event detail as a sheet; item-binding dismisses automatically
            // when selectedEvent is set back to nil.
            .sheet(item: $selectedEvent) { event in
                EventDetailView(event: event)
            }
            .onAppear {
                locationService.requestPermission()
            }
            .onChange(of: locationService.isDenied) { _, denied in
                if denied { viewModel.showLocationDeniedAlert = true }
            }
            .alert("Location Access Denied", isPresented: $viewModel.showLocationDeniedAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Loop uses your location to show nearby events. Enable it in Settings → Privacy & Security → Location Services.")
            }
        }
    }
}

#Preview {
    DiscoverView()
        .modelContainer(for: [Event.self, SavedEvent.self], inMemory: true)
}
