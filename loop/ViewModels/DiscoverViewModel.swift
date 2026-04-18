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

    var hasActiveFilters: Bool {
        showFreeOnly || showToday || showThisWeek || !selectedCategories.isEmpty
    }

    // MARK: - Alert State

    var showLocationDeniedAlert = false

    // MARK: - Filtering + Sorting

    /// Returns events matching all active filters, sorted by distance from `location`.
    func filtered(_ events: [Event], near location: CLLocation) -> [Event] {
        var result = events

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

        // --- Sort by distance from user (or fallback) ---
        result.sort { a, b in
            a.clLocation.distance(from: location) < b.clLocation.distance(from: location)
        }

        return result
    }
}
