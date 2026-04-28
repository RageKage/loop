import SwiftUI

struct YouView: View {
    private var auth: AuthService { AuthService.shared }

    @State private var showSignInSheet = false
    @State private var showSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    profileCard
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 24)
                }

                Section("Activity") {
                    NavigationLink {
                        MyEventsView()
                    } label: {
                        Label("My Events", systemImage: "calendar.badge.clock")
                    }

                    NavigationLink {
                        NotificationPreferencesView()
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }
                }

                Section("App") {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }

                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About", systemImage: "info.circle")
                    }
                }

                if auth.currentIdentity != nil {
                    Section {
                        Button(role: .destructive) {
                            showSignOutConfirmation = true
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSignInSheet) {
                signInSheet
            }
            .onChange(of: auth.isSignedIn) { _, isSignedIn in
                if isSignedIn { showSignInSheet = false }
            }
            .confirmationDialog(
                "Sign out of Loop?",
                isPresented: $showSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    AuthService.shared.signOut()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    @ViewBuilder
    private var profileCard: some View {
        if let identity = auth.currentIdentity {
            signedInCard(identity: identity)
        } else {
            Button {
                showSignInSheet = true
            } label: {
                guestCard
            }
            .buttonStyle(.plain)
        }
    }

    private var guestCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle.dashed")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("Guest")
                .font(.body.weight(.semibold))
            Text("Tap to sign in")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func signedInCard(identity: AuthIdentity) -> some View {
        VStack(spacing: 8) {
            avatar(for: identity)
            Text(identity.displayName ?? "Account")
                .font(.body.weight(.semibold))
            Text("Verified ✓")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func avatar(for identity: AuthIdentity) -> some View {
        Image(systemName: "person.crop.circle.fill")
            .font(.system(size: 64))
            .foregroundStyle(.secondary)
    }

    private var signInSheet: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text("Sign In")
                    .font(.title2.weight(.semibold))
                Text("Post as a verified organizer and manage your hosted events.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            SignInWithGoogleView(onSuccess: { _ in }, onError: { _ in })
        }
        .padding(32)
        .presentationDetents([.medium])
    }
}

#Preview {
    YouView()
}
