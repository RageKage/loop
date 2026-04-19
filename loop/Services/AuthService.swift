import AuthenticationServices
import Foundation
import Security

// MARK: - Auth Keychain

private enum AuthKeychain {
    static let service = "com.niman.loop.auth-identity"
    static let account = "identity"

    static func save(_ identity: AuthIdentity) throws {
        guard let data = try? JSONEncoder().encode(identity) else {
            throw AuthService.AuthError.keychainFailed
        }
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        let existing = SecItemCopyMatching(query as CFDictionary, nil)
        if existing == errSecSuccess {
            let update: [CFString: Any] = [kSecValueData: data]
            guard SecItemUpdate(query as CFDictionary, update as CFDictionary) == errSecSuccess else {
                throw AuthService.AuthError.keychainFailed
            }
        } else if existing == errSecItemNotFound {
            var add = query
            add[kSecValueData] = data
            guard SecItemAdd(add as CFDictionary, nil) == errSecSuccess else {
                throw AuthService.AuthError.keychainFailed
            }
        } else {
            throw AuthService.AuthError.keychainFailed
        }
    }

    static func load() -> AuthIdentity? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(AuthIdentity.self, from: data)
    }

    static func delete() {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - AuthService

@Observable @MainActor
final class AuthService {
    static let shared = AuthService()

    enum AuthError: Error, LocalizedError {
        case keychainFailed
        var errorDescription: String? { "Failed to access the keychain." }
    }

    private(set) var currentIdentity: AuthIdentity?

    var isSignedIn: Bool { currentIdentity != nil }

    private init() {
        currentIdentity = AuthKeychain.load()
    }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) throws {
        let existing = currentIdentity

        // Apple only returns fullName and email on first sign-in.
        // Preserve the stored values if the new credential doesn't provide them.
        let displayName: String? = {
            if let given = credential.fullName?.givenName,
               let family = credential.fullName?.familyName,
               !given.isEmpty || !family.isEmpty {
                return [given, family].filter { !$0.isEmpty }.joined(separator: " ")
            }
            return existing?.displayName
        }()

        let email: String? = credential.email ?? existing?.email

        let identity = AuthIdentity(
            userID: credential.user,
            provider: .apple,
            displayName: displayName,
            email: email,
            createdAt: existing?.createdAt ?? Date()
        )

        try AuthKeychain.save(identity)
        currentIdentity = identity
    }

    func signInWithGoogle(identity: AuthIdentity) throws {
        try AuthKeychain.save(identity)
        currentIdentity = identity
    }

    func signOut() {
        AuthKeychain.delete()
        currentIdentity = nil
    }
}
