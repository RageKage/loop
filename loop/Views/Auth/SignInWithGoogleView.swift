import GoogleSignIn
import SwiftUI
import UIKit

struct SignInWithGoogleView: View {
    let onSuccess: (AuthIdentity) -> Void
    let onError: (Error) -> Void

    var body: some View {
        Button(action: handleTap) {
            HStack(spacing: 10) {
                // TODO: replace with official Google G logo asset
                Image(systemName: "globe")
                    .font(.system(size: 18, weight: .medium))
                Text("Sign in with Google")
                    .font(.system(size: 17, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundStyle(.black)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(.black.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func handleTap() {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let rootVC = windowScene.keyWindow?.rootViewController else {
            onError(GoogleSignInService.SignInError.noRootViewController)
            return
        }

        Task {
            do {
                let identity = try await GoogleSignInService.shared.signIn(presenting: rootVC)
                onSuccess(identity)
            } catch {
                onError(error)
            }
        }
    }
}
