import AuthenticationServices
import SwiftUI

struct SignInWithAppleView: View {
    let onSuccess: (AuthIdentity) -> Void
    let onError: (Error) -> Void

    var body: some View {
        SignInWithAppleButton(.signIn, onRequest: configureRequest, onCompletion: handleCompletion)
            .signInWithAppleButtonStyle(.whiteOutline)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func configureRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    private func handleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                return
            }
            do {
                try AuthService.shared.signInWithApple(credential: credential)
                if let identity = AuthService.shared.currentIdentity {
                    onSuccess(identity)
                }
            } catch {
                onError(error)
            }
        case .failure(let error):
            onError(error)
        }
    }
}
