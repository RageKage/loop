import Foundation

/// Enforces a rolling 24-hour scan quota stored in UserDefaults.
/// Thread-safe for reading; writes hop to the main actor via @Observable.
@Observable
final class RateLimiter {
    private let maxScans   = 20
    private let windowSecs = 86_400.0  // 24 hours
    private let key        = "loop.scanTimestamps"

    /// Timestamps (as TimeIntervals) of scans within the current window.
    private var timestamps: [TimeInterval] {
        get { UserDefaults.standard.array(forKey: key) as? [TimeInterval] ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    /// Number of scans used in the current rolling 24-hour window.
    var scansUsed: Int { pruned().count }

    /// Scans remaining before hitting the quota.
    var scansRemaining: Int { max(0, maxScans - scansUsed) }

    /// Whether another scan is allowed right now.
    func canScan() -> Bool { pruned().count < maxScans }

    /// Seconds until the oldest scan in the window expires and frees a slot.
    /// Returns nil when under quota.
    func secondsUntilReset() -> TimeInterval? {
        let active = pruned()
        guard active.count >= maxScans, let oldest = active.first else { return nil }
        return (oldest + windowSecs) - Date.now.timeIntervalSinceReferenceDate
    }

    /// Records a scan. Call immediately before sending the API request.
    func recordScan() {
        var ts = pruned()
        ts.append(Date.now.timeIntervalSinceReferenceDate)
        timestamps = ts
    }

    /// For the developer settings "clear" action.
    func clearHistory() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    // MARK: - Private

    private func pruned() -> [TimeInterval] {
        let cutoff = Date.now.timeIntervalSinceReferenceDate - windowSecs
        return timestamps.filter { $0 > cutoff }
    }
}
