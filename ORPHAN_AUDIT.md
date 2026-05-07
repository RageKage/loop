# Orphaned Feature Audit

> Generated 2026-05-03. Fix in patches; check off items as they land.

---

## 1. Orphaned — no navigation path at all

- [ ] **`SignInWithAppleView`** (`loop/Views/Auth/SignInWithAppleView.swift`)
  - Only call site is inside `#if false` in `CreateEventFormView.swift:150–155`. Never displayed in any build.
  - **Fix:** Add to `YouView.signInSheet` alongside `SignInWithGoogleView` when the paid Apple Developer account is active.

---

## 2. Conditionally reachable — verify condition still fires

- [ ] **`PendingScansView`** (`loop/Views/Create/PendingScansView.swift`)
  - Reachable only via the banner in `CreateEntryView` when `!pendingScans.isEmpty && networkMonitor.isOnline`.
  - Condition is wired correctly, but there is no tab-icon badge or notification to prompt the user to return to the Create tab. A user who never returns will never discover queued scans.
  - **Fix:** Add a badge to the Create tab icon when `pendingScans` is non-empty.

- [ ] **`APIKeySetupView`** (`loop/Views/Settings/APIKeySetupView.swift`)
  - Entry point (`Button { showAPIKeySetup = true }` in `SettingsView`) is inside `#if DEBUG`. Unreachable in a release build.
  - **Fix:** Move the button outside `#if DEBUG` before shipping, or decide on a release-time API key distribution strategy.

- [ ] **`OnboardingView`** — no replay path in release
  - `OnboardingState.reset()` is only called from `SettingsView` behind `#if DEBUG`. No way for a release user to view onboarding again.
  - Likely intentional, but confirm before shipping.

---

## 3. Reachable but suspicious

- [ ] **`SettingsView` owns its own `NavigationStack` while being pushed from `YouView`'s `NavigationStack`**
  - `YouView` pushes `SettingsView` via `NavigationLink`, but `SettingsView.body` opens with its own `NavigationStack { List { ... } }`. The inner stack hijacks navigation context — pushes from within Settings (e.g. to `NotificationPreferencesView`) happen inside SettingsView's stack, not YouView's. Can cause double back buttons and wrong nav bar titles.
  - **Fix:** Remove the `NavigationStack` wrapper from `SettingsView`; it already gets one from `YouView`.

- [ ] **`EditEventFormView` `onSaved` callback is a no-op**
  - `EventDetailView` passes `onSaved: { _ in }` (line 90). Edit saves silently — no toast, no confirmation. The create flow shows a toast via `CreateView`'s callback chain; the edit-from-detail flow has no equivalent.
  - **Fix:** Wire `onSaved` to dismiss the sheet and show a toast, matching the create flow.

- [ ] **`SettingsView` Location section is a static, non-interactive label**
  - `Section("Location")` contains only `Label("Location Permission", ...).foregroundStyle(.secondary)`. Not a button, not a `NavigationLink`. Implies the user can manage location permission here, but they cannot.
  - **Fix:** Replace with a `Button` that opens `UIApplication.openSettingsURLString`, or remove the section entirely.

- [ ] **`EventReport.synced` is always `false`; no backend receives reports**
  - Reports are inserted locally by `ReportEventSheet.submitReport()`, but `synced` is never set to `true` and there is no network call. The UI tells the user "Report submitted — thanks for helping keep Loop safe," which implies the report was received.
  - **Fix:** Either implement sync (Phase 4c+) or change the success message to set user expectation correctly ("Report saved locally").

- [ ] **`NotificationPreferencesView` reachable from two paths in the same stack**
  - Navigable from `YouView` Activity section (direct `NavigationLink`) *and* from `YouView → Settings → Notification Preferences`. Redundant; may confuse users about where the setting lives.
  - **Fix:** Remove the direct `NavigationLink` from `YouView` Activity section and keep it only under Settings, or vice versa.
