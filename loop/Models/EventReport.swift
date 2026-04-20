import Foundation
import SwiftData

@Model
final class EventReport {
    var id: UUID = UUID()
    var eventID: UUID = UUID()
    var eventTitle: String = ""
    var reason: String = ""
    var details: String = ""
    var reporterUserID: String? = nil
    var createdAt: Date = Date()
    var synced: Bool = false

    init(
        eventID: UUID,
        eventTitle: String,
        reason: String,
        details: String,
        reporterUserID: String?
    ) {
        self.id = UUID()
        self.eventID = eventID
        self.eventTitle = eventTitle
        self.reason = reason
        self.details = details
        self.reporterUserID = reporterUserID
        self.createdAt = Date()
        self.synced = false
    }
}

enum ReportReason: String, CaseIterable, Identifiable {
    case inappropriate = "Inappropriate content"
    case fake = "Fake or fraudulent event"
    case past = "Event has already happened"
    case wrongInfo = "Wrong info (time, location, etc.)"
    case spam = "Spam or promotional"
    case other = "Other"

    var id: String { rawValue }
}
