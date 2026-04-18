import SwiftUI

struct SettingsView: View {
    @State private var showAPIKeySetup = false
    @State private var apiKeyRefreshTrigger = 0

    private var apiKeyConfigured: Bool {
        let _ = apiKeyRefreshTrigger
        return KeychainService.load() != nil
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Location") {
                    Label("Location Permission", systemImage: "location")
                        .foregroundStyle(.secondary)
                }

                Section("Notifications") {
                    Label("Notification Preferences", systemImage: "bell")
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button {
                        showAPIKeySetup = true
                    } label: {
                        if apiKeyConfigured {
                            Text("Claude API Key (configured)")
                                .foregroundStyle(.tint)
                        } else {
                            Text("Set Claude API Key")
                                .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text("Developer")
                } footer: {
                    Text("Required for poster scanning. Coming in the next update.")
                }

                Section("About") {
                    LabeledContent("App", value: "Loop")
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Build", value: "Phase 1 — Foundation")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAPIKeySetup, onDismiss: {
                apiKeyRefreshTrigger += 1
            }) {
                APIKeySetupView()
            }
        }
    }
}

#Preview {
    SettingsView()
}
