import AuthenticationServices
import GoogleSignIn
import SwiftData
import SwiftUI
import UIKit
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    private let notificationService = NotificationService.shared

    @State private var showAPIKeySetup = false
    @State private var apiKeyRefreshTrigger = 0
    @State private var isTesting = false
    @State private var testResult: String? = nil
    @State private var showResult = false
    @State private var rateLimiter = RateLimiter()
    @State private var showSignOutConfirmation = false
    #if DEBUG
    @State private var showConfidenceTest = false
    @State private var showOnboardingResetAlert = false
    @State private var showClearAllEventsConfirmation = false
    @State private var showNotifDebugAlert = false
    @State private var notifDebugMessage = ""
    #endif

    private var apiKeyConfigured: Bool {
        let _ = apiKeyRefreshTrigger
        return KeychainService.load() != nil
    }

    var body: some View {
        NavigationStack {
            List {
                accountSection

                Section("Location") {
                    Label("Location Permission", systemImage: "location")
                        .foregroundStyle(.secondary)
                }

                Section("Notifications") {
                    NavigationLink {
                        NotificationPreferencesView()
                    } label: {
                        HStack {
                            Label("Notification Preferences", systemImage: "bell")
                            Spacer()
                            Text(notificationService.authorizationStatus == .authorized ? "On" : "Off")
                                .font(.subheadline)
                                .foregroundStyle(
                                    notificationService.authorizationStatus == .authorized
                                        ? Color.primary : Color.secondary
                                )
                        }
                    }
                }

                #if DEBUG
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

                    Button {
                        runAPITest()
                    } label: {
                        if isTesting {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 4)
                                Text("Testing…")
                            }
                        } else {
                            Label("Test Claude API", systemImage: "flask")
                        }
                    }
                    .disabled(isTesting)

                    Button("Print Key Fingerprint (debug)") {
                        printKeyFingerprint()
                        testResult = "Check Xcode console"
                        showResult = true
                    }

                    LabeledContent("Scan quota") {
                        Text("\(rateLimiter.scansUsed) / 20")
                            .monospacedDigit()
                            .foregroundStyle(rateLimiter.scansUsed >= 20 ? .red : .secondary)
                    }

                    Button("Reset Scan Quota (debug)") {
                        rateLimiter.reset()
                    }
                    .foregroundStyle(.red)

                    NavigationLink("Force low-confidence scan test") {
                        CreateEventFormView(prefill: .confidenceTestFixture, onPublished: { _ in })
                    }

                    Button("Simulate Past Event (debug)") {
                        simulatePastEvents()
                    }
                    .foregroundStyle(.orange)

                    Button("Reset Onboarding (debug)") {
                        OnboardingState.reset()
                        showOnboardingResetAlert = true
                    }
                    .foregroundStyle(.orange)

                    Button("Clear All Events (debug)", role: .destructive) {
                        showClearAllEventsConfirmation = true
                    }
                    .confirmationDialog(
                        "Delete all events and pending scans? This cannot be undone.",
                        isPresented: $showClearAllEventsConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Confirm", role: .destructive) {
                            try? modelContext.delete(model: Event.self)
                            try? modelContext.delete(model: PendingScan.self)
                            try? modelContext.delete(model: SavedEvent.self)
                            SampleEventSeeder.resetSeedFlag()
                        }
                        Button("Cancel", role: .cancel) {}
                    }

                    Button("Reseed Sample Events (debug)") {
                        SampleEventSeeder.reseed(context: modelContext)
                    }
                    .foregroundStyle(.tint)

                    Button("Cancel All Notifications (debug)") {
                        NotificationService.shared.cancelAllPending()
                        notifDebugMessage = "All pending notifications cleared"
                        showNotifDebugAlert = true
                    }
                    .foregroundStyle(.red)

                    Button("Show Pending Count (debug)") {
                        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                            let n = requests.count
                            Task { @MainActor in
                                notifDebugMessage = "\(n) pending notification\(n == 1 ? "" : "s")"
                                showNotifDebugAlert = true
                            }
                        }
                    }
                } header: {
                    Text("Developer")
                } footer: {
                    Text("Required for poster scanning. Quota resets 24 hours after your first scan of the day.")
                }
                .onAppear { rateLimiter = RateLimiter() }
                #endif

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
            .alert("API Test Result", isPresented: $showResult) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(testResult ?? "")
            }
            #if DEBUG
            .alert("Onboarding Reset", isPresented: $showOnboardingResetAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Onboarding reset. Relaunch the app to see it.")
            }
            .alert("Notifications", isPresented: $showNotifDebugAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(notifDebugMessage)
            }
            #endif
        }
    }

    @ViewBuilder
    private var accountSection: some View {
        if let identity = AuthService.shared.currentIdentity {
            Section("Account") {
                VStack(alignment: .leading, spacing: 2) {
                    Text(identity.displayName ?? (identity.provider == .google ? "Signed in with Google" : "Signed in with Apple"))
                        .font(.body)
                    if let email = identity.email {
                        Text(email.hasSuffix("@privaterelay.appleid.com") ? "Private relay email" : email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)

                Button("Sign Out", role: .destructive) {
                    showSignOutConfirmation = true
                }
                .confirmationDialog("Sign Out", isPresented: $showSignOutConfirmation, titleVisibility: .visible) {
                    Button("Sign Out", role: .destructive) {
                        AuthService.shared.signOut()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("You'll be signed out. Community posts you've made won't be affected.")
                }
            }
        } else {
            Section {
                SignInWithGoogleView(
                    onSuccess: { _ in },
                    onError: { _ in }
                )
                .padding(.vertical, 4)

                // Sign in with Apple requires a paid Apple Developer Program account ($99/yr).
                // Re-enable this block once the paid account is active. See KNOWN_ISSUES.md.
                #if false
                SignInWithAppleView(
                    onSuccess: { _ in },
                    onError: { _ in }
                )
                .padding(.vertical, 4)
                #endif
            } header: {
                Text("Account")
            } footer: {
                Text("Sign in to post as a verified organizer and manage your events.")
            }
        }
    }

    private func runAPITest() {
        guard KeychainService.loadWithDevFallback() != nil else {
            testResult = "Set an API key first."
            showResult = true
            return
        }

        isTesting = true

        Task {
            let imageData = makePosterTestImage()
            do {
                let event = try await ClaudeVisionService.extractEvent(from: imageData)
                let title = event.title ?? "(no title)"
                let category = event.category ?? "(no category)"
                let titleConf = event.confidence?.title ?? "?"
                let dateConf = event.confidence?.date ?? "?"
                testResult = "Title: \(title)\nCategory: \(category)\nConfidence — title: \(titleConf), date: \(dateConf)"
            } catch {
                testResult = error.localizedDescription
            }
            isTesting = false
            showResult = true
        }
    }

    private func printKeyFingerprint() {
        guard let key = KeychainService.loadWithDevFallback() else {
            print("🔑 No key saved")
            print("🔑 Source: none")
            return
        }
        if KeychainService.load() != nil {
            print("🔑 Source: Keychain")
        } else {
            #if DEBUG
            print("🔑 Source: DevAPIKey.swift (DEBUG)")
            #else
            print("🔑 Source: none")
            #endif
        }
        print("🔑 Key length: \(key.count)")
        print("🔑 First 8: \(String(key.prefix(8)))")
        print("🔑 Last 8: \(String(key.suffix(8)))")
        print("🔑 Starts with sk-ant-: \(key.hasPrefix("sk-ant-"))")
        print("🔑 Contains whitespace/newlines: \(key.rangeOfCharacter(from: .whitespacesAndNewlines) != nil)")
    }

    #if DEBUG
    private func simulatePastEvents() {
        let twoDaysAgo = Date.now.addingTimeInterval(-48 * 3600)
        let community = Event(
            title: "DEBUG Community Past Event",
            eventDescription: "Simulated community event 2 days ago.",
            startDate: twoDaysAgo,
            endDate: twoDaysAgo.addingTimeInterval(3600),
            locationName: "Test Location",
            latitude: 44.9778, longitude: -93.2650,
            organizerName: "Community Tester",
            isApproved: true,
            creatorType: "community"
        )
        let verified = Event(
            title: "DEBUG Verified Past Event",
            eventDescription: "Simulated verified event 2 days ago.",
            startDate: twoDaysAgo,
            endDate: twoDaysAgo.addingTimeInterval(3600),
            locationName: "Test Location",
            latitude: 44.9778, longitude: -93.2650,
            organizerName: "Verified Tester",
            isApproved: true,
            creatorID: AuthService.shared.currentIdentity?.userID ?? "debug-user",
            creatorType: "verified",
            creatorDisplayName: AuthService.shared.currentIdentity?.displayName ?? "Debug Organizer"
        )
        modelContext.insert(community)
        modelContext.insert(verified)
        print("DEBUG community past event ID: \(community.id.uuidString)")
        print("DEBUG verified past event ID:  \(verified.id.uuidString)")
    }
    #endif

    private func makePosterTestImage() -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 400))
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 600, height: 400))

            let lines = [
                ("Lake Harriet Run Club", UIFont.boldSystemFont(ofSize: 36), 60.0),
                ("Every Saturday 7am", UIFont.systemFont(ofSize: 28), 130.0),
                ("Free", UIFont.systemFont(ofSize: 24), 190.0),
                ("Organized by Minneapolis Runners", UIFont.systemFont(ofSize: 20), 240.0),
            ]

            let style = NSMutableParagraphStyle()
            style.alignment = .center

            for (text, font, y) in lines {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.black,
                    .paragraphStyle: style,
                ]
                let rect = CGRect(x: 20, y: y, width: 560, height: 50)
                text.draw(in: rect, withAttributes: attrs)
            }
        }
        return image.jpegData(compressionQuality: 0.9) ?? Data()
    }
}

#Preview {
    SettingsView()
}
