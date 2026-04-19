import SwiftUI
import SwiftData

@main
struct loopApp: App {
    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            Event.self,
            SavedEvent.self,
            PendingScan.self,
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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
