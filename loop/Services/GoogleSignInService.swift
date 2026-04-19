import GoogleSignIn
import UIKit

@MainActor
final class GoogleSignInService {
    static let shared = GoogleSignInService()

    enum SignInError: Error, LocalizedError {
        case notConfigured
        case missingUserID
        case noRootViewController

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "Google Sign-In is not configured. Add your client ID to DevAPIKey.swift."
            case .missingUserID:
                return "Google did not return a stable user ID."
            case .noRootViewController:
                return "Could not find a view controller to present sign-in."
            }
        }
    }

    private init() {}

    static func configure() {
        #if DEBUG
        guard let clientID = DevAPIKey.googleClientID else {
            print("⚠️ [GoogleSignIn] No client ID in DevAPIKey.googleClientID — sign-in will fail.")
            return
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        #endif

        checkReversedClientIDPlaceholder()
    }

    func signIn(presenting viewController: UIViewController) async throws -> AuthIdentity {
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
        let user = result.user

        guard let userID = user.userID else {
            throw SignInError.missingUserID
        }

        let identity = AuthIdentity(
            userID: userID,
            provider: .google,
            displayName: user.profile?.name,
            email: user.profile?.email,
            createdAt: Date()
        )

        try AuthService.shared.signInWithGoogle(identity: identity)
        return identity
    }

    func handleURL(_ url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }

    // MARK: - Private

    private static func checkReversedClientIDPlaceholder() {
        guard let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] else {
            return
        }
        for entry in urlTypes {
            if let schemes = entry["CFBundleURLSchemes"] as? [String],
               schemes.contains("REVERSED_CLIENT_ID_PLACEHOLDER") {
                print("⚠️ [GoogleSignIn] Replace REVERSED_CLIENT_ID_PLACEHOLDER in Info.plist with your reversed client ID (e.g. com.googleusercontent.apps.YOUR_CLIENT_ID).")
            }
        }
    }
}
