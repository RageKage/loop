import Foundation

@Observable @MainActor
final class RateLimiter {
    private static let udKey = "scanTimestamps"
    private static let maxScans = 20
    private static let windowInterval: TimeInterval = 24 * 3600

    private var _timestamps: [Date]

    init() {
        _timestamps = Self.loadFromDefaults()
    }

    var scansUsed: Int { active().count }
    var remainingScans: Int { max(0, Self.maxScans - scansUsed) }
    var canScan: Bool { remainingScans > 0 }

    var nextResetAt: Date? {
        active().min().map { $0.addingTimeInterval(Self.windowInterval) }
    }

    func recordScan() {
        var ts = active()
        ts.append(Date())
        _timestamps = ts
        Self.saveToDefaults(ts)
    }

    func reset() {
        _timestamps = []
        Self.saveToDefaults([])
    }

    private func active() -> [Date] {
        let cutoff = Date().addingTimeInterval(-Self.windowInterval)
        return _timestamps.filter { $0 > cutoff }
    }

    private static func loadFromDefaults() -> [Date] {
        guard let data = UserDefaults.standard.data(forKey: udKey),
              let dates = try? JSONDecoder().decode([Date].self, from: data)
        else { return [] }
        return dates
    }

    private static func saveToDefaults(_ dates: [Date]) {
        guard let data = try? JSONEncoder().encode(dates) else { return }
        UserDefaults.standard.set(data, forKey: udKey)
    }
}
