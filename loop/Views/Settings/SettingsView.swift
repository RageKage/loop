import SwiftData
import SwiftUI

struct SettingsView: View {
    @State private var showAPIKeySetup  = false
    @State private var rateLimiter      = RateLimiter()
    @State private var showClearConfirm = false

    @Query private var pendingScans: [PendingScan]
    @Environment(\.modelContext) private var modelContext

    private var apiKeyConfigured: Bool { KeychainService.load() != nil }

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

                // Developer section — always visible so dev workflow is frictionless.
                // Wire to #if DEBUG if you want to hide from TestFlight builds later.
                Section {
                    // API key row
                    Button {
                        showAPIKeySetup = true
                    } label: {
                        HStack {
                            Label(
                                apiKeyConfigured ? "Claude API Key (configured)" : "Set Claude API Key",
                                systemImage: "key"
                            )
                            .foregroundStyle(apiKeyConfigured ? Color.primary : Color.red)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    // Scan quota
                    LabeledContent {
                        Text("\(rateLimiter.scansUsed) / 20 used today")
                            .foregroundStyle(rateLimiter.scansUsed >= 20 ? .red : .secondary)
                    } label: {
                        Label("Scan Quota", systemImage: "camera.badge.clock")
                    }

                    // Pending scans
                    if !pendingScans.isEmpty {
                        LabeledContent {
                            Text("\(pendingScans.count) waiting")
                                .foregroundStyle(.orange)
                        } label: {
                            Label("Pending Scans", systemImage: "clock.badge.exclamationmark")
                        }

                        Button("Clear Pending Scans", role: .destructive) {
                            showClearConfirm = true
                        }
                    }
                } header: {
                    Text("Developer")
                } footer: {
                    Text("Poster scanning uses the Claude API. Scans are counted per device per rolling 24 hours.")
                }

                Section("About") {
                    LabeledContent("App", value: "Loop")
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Build", value: "Phase 4a — Poster Scanner")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAPIKeySetup) {
                APIKeySetupView()
            }
            .confirmationDialog(
                "Clear all saved posters?",
                isPresented: $showClearConfirm,
                titleVisibility: .visible
            ) {
                Button("Clear \(pendingScans.count) Poster\(pendingScans.count == 1 ? "" : "s")", role: .destructive) {
                    for scan in pendingScans { modelContext.delete(scan) }
                }
                Button("Keep") {}
            } message: {
                Text("This cannot be undone.")
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Event.self, SavedEvent.self, PendingScan.self], inMemory: true)
}
