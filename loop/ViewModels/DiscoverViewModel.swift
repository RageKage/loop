import CoreLocation
import Observation

/// UI state for the Discover tab.
///
/// Intentionally thin: @Query in the view handles data fetching;
/// this view model handles view state and filtering only.
@Observable
final class DiscoverViewModel {

    // MARK: - Display Mode

    enum DisplayMode {
        case map, list
    }

    var displayMode: DisplayMode = .map

    // MARK: - Filter State

    var showFreeOnly = false
    var showToday    = false
    var showThisWeek = false
    var selectedCategories: Set<EventCategory> = []

    var searchText: String = ""

    var hasActiveFilters: Bool {
        showFreeOnly || showToday || showThisWeek || !selectedCategories.isEmpty
            || !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Alert State

    var showLocationDeniedAlert = false

    // MARK: - Filtering + Sorting

    /// Returns events matching all active filters, sorted by distance from `location`.
    func filtered(_ events: [Event], near location: CLLocation) -> [Event] {
        // Remove expired community events before any user-facing filters.
        var result = events.filter { !EventTrustSignal.isExpired($0) }

        // --- Filters ---
        if showFreeOnly {
            result = result.filter(\.isFree)
        }

        let now = Date.now
        if showToday {
            result = result.filter { Calendar.current.isDateInToday($0.startDate) }
        } else if showThisWeek {
            let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
            result = result.filter { $0.startDate >= now && $0.startDate <= weekEnd }
        }

        if !selectedCategories.isEmpty {
            result = result.filter { selectedCategories.contains($0.categoryEnum) }
        }

        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            result = result.filter { event in
                event.title.lowercased().contains(query) ||
                event.locationName.lowercased().contains(query) ||
                event.creatorDisplayName?.lowercased().contains(query) ?? false
            }
        }

        // --- Sort by distance from user (or fallback) ---
        result.sort { a, b in
            a.clLocation.distance(from: location) < b.clLocation.distance(from: location)
        }

        return result
    }
}
