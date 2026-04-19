import Foundation

// MARK: - RecurrenceOption

enum RecurrenceOption: String, CaseIterable, Identifiable {
    case none    = "none"
    case daily   = "daily"
    case weekly  = "weekly"
    case monthly = "monthly"

    var id: Self { self }

    var displayName: String {
        switch self {
        case .none:    "None"
        case .daily:   "Daily"
        case .weekly:  "Weekly"
        case .monthly: "Monthly"
        }
    }

    /// Returns the RRULE string for this option, or nil for .none.
    func rrule(byday: String? = nil) -> String? {
        switch self {
        case .none:    nil
        case .daily:   "FREQ=DAILY"
        case .weekly:  byday.map { "FREQ=WEEKLY;BYDAY=\($0)" } ?? "FREQ=WEEKLY"
        case .monthly: "FREQ=MONTHLY"
        }
    }
}

// MARK: - WeekdayOption

/// Day-of-week picker for weekly recurrence, using RFC 5545 two-letter codes.
enum WeekdayOption: String, CaseIterable, Identifiable {
    case sunday    = "SU"
    case monday    = "MO"
    case tuesday   = "TU"
    case wednesday = "WE"
    case thursday  = "TH"
    case friday    = "FR"
    case saturday  = "SA"

    var id: Self { self }

    var displayName: String {
        switch self {
        case .sunday:    "Sunday"
        case .monday:    "Monday"
        case .tuesday:   "Tuesday"
        case .wednesday: "Wednesday"
        case .thursday:  "Thursday"
        case .friday:    "Friday"
        case .saturday:  "Saturday"
        }
    }

    /// Returns the WeekdayOption matching the weekday of `date`.
    static func from(date: Date) -> WeekdayOption {
        switch Calendar.current.component(.weekday, from: date) {
        case 1:  return .sunday
        case 2:  return .monday
        case 3:  return .tuesday
        case 4:  return .wednesday
        case 5:  return .thursday
        case 6:  return .friday
        default: return .saturday
        }
    }
}

// MARK: - FormField

/// Tags for individual form fields, used to track which fields have been
/// interacted with (so validation errors appear lazily, not all at once).
enum FormField: Hashable {
    case title, description, locationName, organizerName, price, startDate, endDate
}

// MARK: - CreateEventViewModel

/// Owns all mutable form state and validation logic for the create-event form.
/// The view holds this as @State; the form writes directly via @Bindable.
@Observable
final class CreateEventViewModel {

    // MARK: - Form Fields

    var title              = ""
    var eventDescription   = ""
    var category: EventCategory = .social

    // Start: tomorrow at 7 PM
    var startDate: Date = {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now)!
        return Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }()

    var hasEndDate = false
    // End: tomorrow at 8 PM (start + 1 hour)
    var endDate: Date = {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now)!
        return Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }()

    var recurrence: RecurrenceOption = .none
    // Weekday pre-filled to match the initial start date (a Saturday if tomorrow
    // happens to be Saturday; otherwise updated live as the user changes start date).
    var weekday: WeekdayOption = {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now)!
        return WeekdayOption.from(date: tomorrow)
    }()

    var locationName = ""
    var address      = ""
    // Default pin: downtown Minneapolis. Updated via map tap or address geocoding.
    var latitude  = 44.9778
    var longitude = -93.2650

    var isFree       = true
    var priceString  = ""   // TextField text; converted to Double on publish

    var organizerName    = ""
    var organizerContact = ""

    // MARK: - Interaction Tracking

    /// Fields the user has touched at least once.
    var touchedFields: Set<FormField> = []
    /// Set to true when the user taps Publish; surfaces all validation errors.
    var publishAttempted = false

    // MARK: - Computed State

    var isDirty: Bool {
        !title.isEmpty || !eventDescription.isEmpty
            || !locationName.isEmpty || !organizerName.isEmpty
    }

    /// RRULE string derived from recurrence + weekday selections.
    var rruleString: String? {
        recurrence.rrule(byday: recurrence == .weekly ? weekday.rawValue : nil)
    }

    // MARK: - Validation

    var validationErrors: [FormField: String] {
        var errors: [FormField: String] = [:]

        let trimTitle = title.trimmingCharacters(in: .whitespaces)
        if trimTitle.isEmpty {
            errors[.title] = "Title is required"
        } else if title.count > 80 {
            errors[.title] = "Title must be 80 characters or fewer"
        }

        let trimDesc = eventDescription.trimmingCharacters(in: .whitespaces)
        if trimDesc.isEmpty {
            errors[.description] = "Description is required"
        } else if eventDescription.count > 500 {
            errors[.description] = "Description must be 500 characters or fewer"
        }

        if locationName.trimmingCharacters(in: .whitespaces).isEmpty {
            errors[.locationName] = "Location name is required"
        }

        if organizerName.trimmingCharacters(in: .whitespaces).isEmpty {
            errors[.organizerName] = "Organizer name is required"
        }

        if !isFree {
            if priceString.isEmpty {
                errors[.price] = "Enter a price for this paid event"
            } else if let val = Double(priceString), val <= 0 {
                errors[.price] = "Price must be greater than zero"
            } else if Double(priceString) == nil {
                errors[.price] = "Enter a valid number (e.g. 10 or 12.50)"
            }
        }

        if startDate <= Date.now {
            errors[.startDate] = "Start date must be in the future"
        }

        if hasEndDate && endDate <= startDate {
            errors[.endDate] = "End time must be after start time"
        }

        return errors
    }

    var isValid: Bool { validationErrors.isEmpty }

    /// True if the error for `field` should be shown to the user right now.
    func shouldShowError(for field: FormField) -> Bool {
        publishAttempted || touchedFields.contains(field)
    }

    /// The visible error message for `field`, or nil if not yet surfaced.
    func visibleError(for field: FormField) -> String? {
        guard shouldShowError(for: field) else { return nil }
        return validationErrors[field]
    }

    // MARK: - Init

    init(prefill: ExtractedEvent? = nil) {
        guard let p = prefill else { return }
        title = p.title ?? ""
        eventDescription = p.description ?? ""
        if let raw = p.category, let cat = EventCategory(rawValue: raw) { category = cat }
        if let iso = p.startISO, let date = Self.parseISO(iso) { startDate = date }
        if let iso = p.endISO, let date = Self.parseISO(iso) {
            endDate = date
            hasEndDate = true
        }
        if let rrule = p.recurrenceRRule {
            recurrence = rrule.contains("FREQ=WEEKLY") ? .weekly : .none
        }
        locationName = p.locationName ?? ""
        address = p.address ?? ""
        if let free = p.isFree { isFree = free }
        if let price = p.priceUSD {
            isFree = false
            priceString = price == price.rounded() ? String(Int(price)) : String(price)
        }
        organizerName = p.organizerName ?? ""
    }

    private static func parseISO(_ string: String) -> Date? {
        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = withFractional.date(from: string) { return d }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: string)
    }

    // MARK: - Build

    /// Constructs the Event model ready to be inserted into a ModelContext.
    func buildEvent() -> Event {
        Event(
            title: title.trimmingCharacters(in: .whitespaces),
            eventDescription: eventDescription.trimmingCharacters(in: .whitespaces),
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            recurrenceRule: rruleString,
            locationName: locationName.trimmingCharacters(in: .whitespaces),
            latitude: latitude,
            longitude: longitude,
            address: address.isEmpty ? nil : address.trimmingCharacters(in: .whitespaces),
            isFree: isFree,
            price: isFree ? nil : Double(priceString),
            category: category.rawValue,
            organizerName: organizerName.trimmingCharacters(in: .whitespaces),
            organizerContact: organizerContact.isEmpty ? nil : organizerContact,
            isApproved: true
        )
    }
}
