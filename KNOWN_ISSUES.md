# Known Issues

Tracking bugs we've flagged but deferred. Not blocking for current phase.

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

- **Confidence prompt tuning** — Haiku returns `"high"` on all fields even for degraded/low-quality poster images. Needs prompt tuning in `ClaudeVisionService` extraction prompt. Consider adding explicit rules like "use 'low' if you're inferring a field rather than reading it directly."
- **SF Symbol `calendar.clock` warning** — Should be `calendar.badge.clock`. Console warning only, not user-visible. Grep the project for `calendar.clock` to locate.
- **🟡 Debug log cleanup** — Leftover from confidence-highlight diagnostics. Should be removed after verification. Files: `CreateEventViewModel.swift`, `ClaudeVisionService.swift`, `ConfidenceStyle.swift`, `DiscoverViewModel.swift` (Fix 2 expiry log).
- **#if DEBUG gate on Developer section** — Developer settings are currently always visible; should be wrapped in `#if DEBUG`.

## Phase 4a — Poster Scanner

1. **No future-date guard on extracted events**
   - If poster says "July 28" with no year, Claude picks 2025 (past)
   - Should default to next future occurrence when year is ambiguous
   - Fix location: extraction prompt in `ClaudeVisionService`
