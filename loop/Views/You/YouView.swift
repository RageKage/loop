import SwiftUI

struct YouView: View {
    private var auth: AuthService { AuthService.shared }

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
                        Text("My Events stub")
                    } label: {
                        Label("My Events", systemImage: "calendar.badge.clock")
                    }

                    NavigationLink {
                        Text("Notifications stub")
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }
                }

                Section("App") {
                    NavigationLink {
                        Text("Settings stub")
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }

                    NavigationLink {
                        Text("About stub")
                    } label: {
                        Label("About", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("You")
        }
    }

    @ViewBuilder
    private var profileCard: some View {
        if let identity = auth.currentIdentity {
            signedInCard(identity: identity)
        } else {
            guestCard
        }
    }

    private var guestCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle.dashed")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("Guest")
                .font(.body.weight(.semibold))
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
}

#Preview {
    YouView()
}
