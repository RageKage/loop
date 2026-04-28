import SwiftUI

struct YouView: View {
    private var auth: AuthService { AuthService.shared }

    @State private var showSignInSheet = false
    @State private var showSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                // 1. Dynamic Header Section based on Auth State
                if let identity = auth.currentIdentity {
                    signedInSection(identity: identity)
                } else {
                    communityMemberSection
                }

                // 2. Activity Section
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

                // 3. App Settings Section
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

                // 4. Centered Destructive Action
                if auth.currentIdentity != nil {
                    Section {
                        Button(role: .destructive) {
                            showSignOutConfirmation = true
                        } label: {
                            Text("Sign Out")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            }
             // Restored the native iOS large title
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

    // MARK: - Native iOS Profile Sections

    private var communityMemberSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 16) {
                    Image(systemName: "person.2.circle.fill")
                        .font(.system(size: 46))
                        .foregroundStyle(.tertiary, .tint)
                        .symbolRenderingMode(.palette)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Community Member")
                            .font(.headline)
                        Text("Browsing anonymously")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text("Want to host official events? Sign in as a verified organizer to create and manage your community presence.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button {
                    showSignInSheet = true
                } label: {
                    Text("Sign in as Organizer")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .padding(.top, 4)
            }
            .padding(.vertical, 6)
        }
    }

    private func signedInSection(identity: AuthIdentity) -> some View {
        Section {
            HStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(.white, .blue)
                    .symbolRenderingMode(.palette)

                VStack(alignment: .leading, spacing: 2) {
                    Text(identity.displayName ?? "Account")
                        .font(.headline)
                    Text("Verified Organizer")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 6)
        }
    }

    // MARK: - Sign In Sheet

    private var signInSheet: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .padding(.bottom, 8)
            
            VStack(spacing: 8) {
                Text("Become an Organizer")
                    .font(.title2.bold())
                Text("Sign in to post as a verified organizer and manage your hosted events.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            SignInWithGoogleView(onSuccess: { _ in }, onError: { _ in })
                .padding(.top, 16)
        }
        .padding(32)
        .presentationDetents([.fraction(0.45), .medium]) // Snaps nicely on modern iOS
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    YouView()
}
