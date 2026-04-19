import Foundation

enum AuthProvider: String, Codable, Sendable {
    case apple, google
}

struct AuthIdentity: Codable, Sendable, Equatable {
    let userID: String
    let provider: AuthProvider
    let displayName: String?
    let email: String?
    let createdAt: Date
}
