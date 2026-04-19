# Known Issues

Tracking bugs we've flagged but deferred. Not blocking for current phase.

## Phase 4a — Poster Scanner

1. **ISO date parsing drops timezone-offset dates**
   - Claude returns e.g. `"2025-07-28T22:00:00-05:00"`, form lands on today instead
   - Likely `ISO8601DateFormatter.formatOptions` missing `.withTimeZone` / `.withColonSeparatorInTimeZone`
   - Fix attempted in `CreateEventViewModel.parseISO` but still failing
   - Severity: HIGH — causes silent data corruption on scanned events
   - Files: `loop/ViewModels/CreateEventViewModel.swift`

2. **🟡 debug logs still print**
   - Left over from confidence-highlight diagnostics
   - Should have been removed after verification
   - Files: `CreateEventViewModel.swift`, `ClaudeVisionService.swift`, `ConfidenceStyle.swift`

3. **SF Symbol warning: `calendar.clock` not found**
   - Should be `calendar.badge.clock`
   - Console warning only, not user-visible
   - Grep the project for `calendar.clock` to locate

4. **Confidence scoring too permissive**
   - Haiku returns `"high"` on all fields even for degraded/low-quality poster images
   - Confidence highlighting never fires in real use
   - Needs prompt tuning in `ClaudeVisionService` extraction prompt
   - Consider: add explicit rules like "use 'low' if you're inferring a field rather than reading it directly"

5. **No future-date guard on extracted events**
   - If poster says "July 28" with no year, Claude picks 2025 (past)
   - Should default to next future occurrence when year is ambiguous
   - Fix location: extraction prompt in `ClaudeVisionService`
