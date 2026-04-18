import Foundation
import SwiftData

// MARK: - SavedEventStatus

enum SavedEventStatus: String, CaseIterable, Sendable {
    case going
    case interested

    var displayName: String {
        switch self {
        case .going:       "I'm Going"
        case .interested:  "Interested"
        }
    }

    var systemImage: String {
        switch self {
        case .going:       "checkmark.circle.fill"
        case .interested:  "star.fill"
        }
    }
}

// MARK: - SavedEvent

/// Tracks a user's RSVP state for an event.
/// Stored only in the user's private CloudKit database — never the public one.
///
/// Design note: this stores `eventID` (a UUID) rather than a SwiftData relationship
/// to `Event`. A direct relationship would cross the public/private CloudKit database
/// boundary, which is not supported. The join is done in memory at query time.
///
/// CloudKit sync constraints satisfied:
///  - No @Attribute(.unique) constraints.
///  - All stored properties have default values.
///  - No required relationships.
@Model
final class SavedEvent {
    var eventID: UUID       // References Event.id in the public database
    var status: String      // Stores SavedEventStatus.rawValue
    var savedAt: Date

    init(
        eventID: UUID = UUID(),
        status: String = SavedEventStatus.interested.rawValue,
        savedAt: Date = .now
    ) {
        self.eventID = eventID
        self.status = status
        self.savedAt = savedAt
    }

    /// Typed convenience accessor.
    var statusEnum: SavedEventStatus {
        SavedEventStatus(rawValue: status) ?? .interested
    }
}
