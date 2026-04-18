import Foundation
import SwiftData

// MARK: - EventCategory

/// Backed by a raw String so it round-trips through SwiftData / CloudKit without issues.
enum EventCategory: String, CaseIterable, Sendable {
    case fitness
    case books
    case social
    case music
    case food
    case kids
    case outdoors
    case other

    var displayName: String {
        switch self {
        case .fitness:  "Fitness"
        case .books:    "Books"
        case .social:   "Social"
        case .music:    "Music"
        case .food:     "Food & Drinks"
        case .kids:     "Kids"
        case .outdoors: "Outdoors"
        case .other:    "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .fitness:  "figure.run"
        case .books:    "book"
        case .social:   "person.3"
        case .music:    "music.note"
        case .food:     "fork.knife"
        case .kids:     "figure.and.child.holdinghands"
        case .outdoors: "tree"
        case .other:    "star"
        }
    }
}

// MARK: - Event

/// Public-facing community event, intended for the CloudKit public database in Phase 2.
///
/// CloudKit sync constraints satisfied:
///  - No @Attribute(.unique) — CloudKit does not support unique constraints.
///  - Every stored property has a default value — CloudKit requires this for schema evolution.
///  - No required relationships — all relationships must be optional for CloudKit sync.
///  - `price` uses Double instead of Decimal — Decimal is not a CloudKit-native type.
@Model
final class Event {
    var id: UUID
    var title: String
    var eventDescription: String    // "description" is reserved in ObjC; avoid it as a property name
    var startDate: Date
    var endDate: Date?
    var recurrenceRule: String?     // RRULE format, e.g. "FREQ=WEEKLY;BYDAY=SA"
    var locationName: String
    var latitude: Double
    var longitude: Double
    var address: String?
    var isFree: Bool
    var price: Double?              // Stores dollar amount; nil when isFree is true
    var category: String            // Stores EventCategory.rawValue
    var organizerName: String
    var organizerContact: String?
    var posterImageData: Data?
    var attendeeCount: Int
    var createdAt: Date
    var isApproved: Bool            // Moderation gate before public visibility

    init(
        id: UUID = UUID(),
        title: String = "",
        eventDescription: String = "",
        startDate: Date = .now,
        endDate: Date? = nil,
        recurrenceRule: String? = nil,
        locationName: String = "",
        latitude: Double = 0.0,
        longitude: Double = 0.0,
        address: String? = nil,
        isFree: Bool = true,
        price: Double? = nil,
        category: String = EventCategory.other.rawValue,
        organizerName: String = "",
        organizerContact: String? = nil,
        posterImageData: Data? = nil,
        attendeeCount: Int = 0,
        createdAt: Date = .now,
        isApproved: Bool = false
    ) {
        self.id = id
        self.title = title
        self.eventDescription = eventDescription
        self.startDate = startDate
        self.endDate = endDate
        self.recurrenceRule = recurrenceRule
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.isFree = isFree
        self.price = price
        self.category = category
        self.organizerName = organizerName
        self.organizerContact = organizerContact
        self.posterImageData = posterImageData
        self.attendeeCount = attendeeCount
        self.createdAt = createdAt
        self.isApproved = isApproved
    }

    /// Typed convenience accessor; falls back to `.other` for any unknown raw value.
    var categoryEnum: EventCategory {
        EventCategory(rawValue: category) ?? .other
    }
}
