import Foundation
import SwiftData

/// A poster photo saved for later scanning (e.g. captured while offline).
/// Stored locally until the user returns online and triggers the scan.
@Model
final class PendingScan {
    var id: UUID
    var imageData: Data
    var createdAt: Date

    init(
        id: UUID = UUID(),
        imageData: Data,
        createdAt: Date = .now
    ) {
        self.id = id
        self.imageData = imageData
        self.createdAt = createdAt
    }
}
