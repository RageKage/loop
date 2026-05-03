# Known Issues

Tracking bugs we've flagged but deferred. Not blocking for current phase.

## Phase 5-c notifications need real-device verification

**Status:** Code shipped, simulator testing inconclusive.

**What works:**
- NotificationService scheduling logic compiles, prints diagnostic logs at scheduling time
- Wired to publish flow (CreateEventFormView publishButton line 108)
- Permission request flow works in NotificationPreferencesView
- Category subscription persistence via UserDefaults works
- RSVP scheduling logic exists and triggers on "I'm Going"

**What's unverified:**
- Whether banners actually fire on real iOS device when scheduled
- Whether 1-hour RSVP reminders deliver at the right time
- Whether the 10-mile radius distance check works correctly when userLocation is populated

**Why deferred:**
- Simulator notification delivery is notoriously flaky on iOS 26
- Paid Apple Developer Program ($99/yr) needed for real-device install
- During testing, console regression occurred after applying category Binding(get:set:) fix and userLocation graceful fallback — root cause unclear without fresh debugging session

**Next steps when reopening:**
1. Fresh clean build (Cmd+Shift+K then rebuild)
2. Test on real iPhone via TestFlight or direct install
3. Verify pending count increments on Settings → Developer → Show Pending Count
4. Verify actual banner delivery
5. If broken, the diagnostic 🔔 prints in NotificationService and CreateEventFormView publishButton are still in place to debug from

## Deferred Features

### Anonymous RSVPs are device-local
SavedEvent records with userID == nil don't sync across devices. A user who
taps "I'm Going" anonymously on their iPhone won't see it on their iPad, and
loses them entirely if the app is deleted or the phone is replaced. Two possible
fixes later:
- (a) Gate RSVPs behind sign-in like we gate event creation
- (b) Tie anonymous RSVPs to a per-install UUID stored in Keychain, so they
      survive reinstall via iCloud Keychain sync
Fine for MVP / TestFlight. Revisit before App Store launch.

### Sign in with Apple — deferred to paid Apple Developer account
Apple's free-tier Personal Team cannot use the Sign in with Apple capability.
The plumbing is fully implemented (SignInWithAppleView, AuthService Apple flow,
entitlements) but currently wrapped in `#if false` in SettingsView and
CreateEventFormView. Re-enable when upgrading to the $99/yr Apple Developer Program.
Also required for CloudKit sync (Phase 4c) and Push Notifications.

## Phase 4-fixes-a shipped

- In-app Report sheet replaces mailto flow ✅
- Community post auto-expiry confirmed working via logs ✅
- Past-date warning banner on AI-extracted events ✅

### Past-date posters silently snap to today (now addressed in Phase 4-fixes-a)
When an AI-scanned poster has a date in the past, the DatePicker's future-only range caused the startDate to silently reset to today. Fixed in Phase 4-fixes-a by removing the range constraint, adding a visible "date is in the past" warning banner, and keeping Publish-time validation.

## Still deferred

- **🟡 Debug log cleanup** — Leftover from confidence-highlight diagnostics. Should be removed after verification. Files: `CreateEventViewModel.swift`, `ClaudeVisionService.swift`, `ConfidenceStyle.swift`, `DiscoverViewModel.swift` (Fix 2 expiry log).
