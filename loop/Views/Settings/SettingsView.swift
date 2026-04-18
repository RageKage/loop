import SwiftUI

/// Phase 1 placeholder. Each section will be wired up as the corresponding
/// feature lands: location in Phase 2, notifications in Phase 4.
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Location") {
                    Label("Location Permission", systemImage: "location")
                        .foregroundStyle(.secondary)
                    // Phase 2: request / show CLAuthorizationStatus here
                }

                Section("Notifications") {
                    Label("Notification Preferences", systemImage: "bell")
                        .foregroundStyle(.secondary)
                    // Phase 4: UNUserNotificationCenter authorization + prefs here
                }

                Section("About") {
                    LabeledContent("App", value: "Loop")
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Build", value: "Phase 1 — Foundation")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
