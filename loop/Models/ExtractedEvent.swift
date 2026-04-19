import Foundation

struct ExtractedEvent: Codable, Sendable {
    var isEventPoster: Bool
    var refused: Bool
    var refusalReason: String?
    var title: String?
    var description: String?
    var startISO: String?
    var endISO: String?
    var recurrenceRRule: String?
    var locationName: String?
    var address: String?
    var isFree: Bool?
    var priceUSD: Double?
    var organizerName: String?
    var category: String?
    var confidence: ConfidenceLevels?

    struct ConfidenceLevels: Codable, Sendable {
        var title: String?
        var date: String?
        var location: String?
        var price: String?
    }

    #if DEBUG
    static var confidenceTestFixture: ExtractedEvent {
        let start = ISO8601DateFormatter().string(
            from: Calendar.current.date(byAdding: .day, value: 7, to: .now)!
        )
        return ExtractedEvent(
            isEventPoster: true,
            refused: false,
            refusalReason: nil,
            title: "Test Event",
            description: "Confidence highlight test",
            startISO: start,
            endISO: nil,
            recurrenceRRule: nil,
            locationName: "Test Venue",
            address: nil,
            isFree: false,
            priceUSD: 10,
            organizerName: "Test",
            category: "social",
            confidence: ConfidenceLevels(title: "high", date: "low", location: "medium", price: "low")
        )
    }
    #endif

    enum CodingKeys: String, CodingKey {
        case isEventPoster = "is_event_poster"
        case refused
        case refusalReason = "refusal_reason"
        case title
        case description
        case startISO = "start_iso"
        case endISO = "end_iso"
        case recurrenceRRule = "recurrence_rrule"
        case locationName = "location_name"
        case address
        case isFree = "is_free"
        case priceUSD = "price_usd"
        case organizerName = "organizer_name"
        case category
        case confidence
    }
}
