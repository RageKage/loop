import GoogleSignIn
import SwiftData
import SwiftUI

@main
struct loopApp: App {
    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            Event.self,
            SavedEvent.self,
            PendingScan.self,
            EventReport.self,
        ])

        // Phase 1: plain on-disk store, no CloudKit sync.
        //
        // TODO: Phase 2 — wire up CloudKit sync by replacing this configuration:
        //
        //   // Public DB: community events visible to everyone (moderated)
        //   let publicConfig = ModelConfiguration(
        //       "public",
        //       schema: Schema([Event.self]),
        //       cloudKitDatabase: .public("iCloud.niman.loop")
        //   )
        //   // Private DB: the signed-in user's RSVPs, invisible to others
        //   let privateConfig = ModelConfiguration(
        //       "private",
        //       schema: Schema([SavedEvent.self]),
        //       cloudKitDatabase: .private("iCloud.niman.loop")
        //   )
        //   modelContainer = try ModelContainer(for: schema,
        //       configurations: [publicConfig, privateConfig])
        //
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        // Seed sample events once on first launch. Running here (not in a view's
        // onAppear) means a debug Clear All Events won't trigger a re-seed on the
        // next tab switch — the call site fires exactly once per app launch.
        SampleEventSeeder.seedIfNeeded(context: ModelContext(modelContainer))

        GoogleSignInService.configure()
    }

    @State private var showOnboarding = !OnboardingState.hasCompleted

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task { await NotificationService.shared.refreshAuthorizationStatus() }
                .onOpenURL { url in
                    _ = GoogleSignInService.shared.handleURL(url)
                }
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView {
                        OnboardingState.markCompleted()
                        showOnboarding = false
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}
