import Foundation

/// Pure presentation logic for community-trust signals.
/// Not @Observable — stateless static helpers only.
struct EventTrustSignal {

    /// Community events expire 48 hours after their end (or start if no end date).
    /// Verified-organizer events never auto-expire.
    static func isExpired(_ event: Event) -> Bool {
        guard event.creatorType == EventCreatorType.community.rawValue else { return false }
        let anchor = event.endDate ?? event.startDate
        return anchor.addingTimeInterval(24 * 3600) < Date.now
    }

    static func isVerified(_ event: Event) -> Bool {
        event.creatorType == EventCreatorType.verified.rawValue && event.creatorID != nil
    }
}
