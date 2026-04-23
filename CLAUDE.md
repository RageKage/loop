# Developer Context
> Full personal knowledge base: ~/Desktop/niman_brain
> Read `Me/Context.md` for background on who I am.
> Read `Me/Stack.md` for tools and preferences.
> Read `Projects/Loop.md` for high-level project summary.

---

# Loop — iOS event discovery app

## What Loop is
Apple-native iOS app for discovering free community events. Users browse a map, create events manually or by snapping a poster photo (Claude Vision API extracts details), RSVP to events, and manage their own hosted events. Community posts are anonymous; verified organizers are identified by a non-nil `creatorID` on the `Event` model.

## Stack
- Swift 6, SwiftUI, iOS 18+ deployment target
- SwiftData for persistence (CloudKit-compatible schema, not yet synced)
- MapKit, CoreLocation, AVFoundation, PhotosUI, EventKit, UserNotifications
- Claude Haiku 4.5 via Anthropic API for poster extraction
- Google Sign-In for auth (Apple Sign In coded but gated behind `#if false` pending paid dev account)

## Key architecture decisions
- `@Observable` (not `ObservableObject`) for view models
- Main-actor default isolation throughout
- `DevAPIKey.swift` pattern for dev secrets (gitignored)
- `PBXFileSystemSynchronizedRootGroup` — new files auto-compile, no `.pbxproj` edits needed
- `Event.creatorID nil` = Community post (anonymous), non-nil = Verified organizer

## File layout (`loop/`)

```
loopApp.swift            — App entry point, SwiftData container setup
ContentView.swift        — Root TabView (Discover / Create / My Events / Settings)

Models/
  Event.swift            — Core SwiftData model, all event fields
  Event+Location.swift   — CLLocationCoordinate2D helpers
  SavedEvent.swift       — RSVP/saved event join model
  EventReport.swift      — User-submitted event reports
  ExtractedEvent.swift   — Transient model from Claude Vision parsing
  PendingScan.swift      — Poster scan queue item
  AuthIdentity.swift     — Signed-in user identity

Services/
  AuthService.swift      — Auth state machine, Google/Apple sign-in dispatch
  GoogleSignInService.swift — Google OAuth wrapper
  ClaudeVisionService.swift — Anthropic API call, poster → ExtractedEvent
  KeychainService.swift  — Secure credential storage with dev fallback
  DevAPIKey.swift        — Dev secrets (gitignored, never commit)
  LocationService.swift  — CLLocationManager wrapper
  NetworkMonitor.swift   — NWPathMonitor reachability
  OnboardingState.swift  — First-launch flag persistence
  RateLimiter.swift      — Throttle for Claude API calls

ViewModels/
  DiscoverViewModel.swift  — Map/list state, filtering, search
  CreateEventViewModel.swift — Form state, poster scan orchestration

Views/
  Auth/                  — SignInWithGoogleView, SignInWithAppleView
  Create/                — CreateView, CreateEventFormView, EditEventFormView,
                           PosterCaptureView, ScanningView, PendingScansView,
                           PosterScanCoordinator, CreateEntryView,
                           PrivacyDisclosureView
  Discover/              — DiscoverView, EventDetailView, EventMapView,
                           EventListView, EventListRowView, EventPinView,
                           FilterBarView
  MyEvents/              — MyEventsView
  Onboarding/            — OnboardingView (3-page, skip-able)
  Settings/              — (settings screens)
  Shared/                — ReportEventSheet, shared reusable components

Utilities/
  DesignTokens.swift     — Centralized colors, typography, spacing
  EventCategory+UI.swift — SF Symbol + color per category
  EventTrustSignal.swift — Badge logic (community vs verified)
  ConfidenceStyle.swift  — Extraction-confidence visual treatment
  RRuleFormatter.swift   — Recurrence rule formatting
  ToastModifier.swift    — In-app toast overlay
  SampleEventSeeder.swift — Dev-only seed data

Resources/Fonts/         — Bundled custom fonts
Assets.xcassets/         — App icons, accent/background/surface/text color sets
```

## Current phase status
- **Shipped:** Phase 1–4 (foundation through trust signals), Phase 4-fixes-a/b (polish), Phase 5-a (onboarding), Phase 5-b (search)
- **In progress:** Phase 5 — next is 5-e (Discover polish)
- **Deferred:** Phase 4c (CloudKit sync — needs $99 Apple Developer Program), Apple Sign In (same reason)

## Coding conventions
- Swift 6 strict concurrency; main-actor default on all view models and services
- SwiftUI `Form`/`Section` for forms, `List` for scrolling lists
- Use `.searchable()` and `.confirmationDialog()` — prefer native iOS patterns
- Shared/reusable views go in `loop/Views/Shared/` — don't duplicate across features
- Don't modify `Event`, `SavedEvent`, or core models without noting the schema change (SwiftData migrations needed if deployed)

## Known issues
`KNOWN_ISSUES.md` in repo root tracks deferred bugs. Skim it before touching related systems.

## DevAPIKey.swift (gitignored)
Holds Anthropic API key and Google OAuth iOS client ID.  
Read via `KeychainService.loadWithDevFallback()` or `GoogleSignInService.configure()`.  
Never commit this file. If missing, create it from the template in the project README or ask the user.

## How to build
Open `loop.xcodeproj` in Xcode → select iPhone 17 Pro simulator → ⌘R. No pre-build steps needed.
