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
