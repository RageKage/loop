import Foundation
import SwiftData

@Model
final class PendingScan {
    var id: UUID = UUID()
    var imageData: Data = Data()
    var createdAt: Date = Date()

    init(imageData: Data) {
        self.id = UUID()
        self.imageData = imageData
        self.createdAt = Date()
    }
}
