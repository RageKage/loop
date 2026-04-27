import CoreLocation
import Foundation
import UserNotifications

@Observable
@MainActor
final class NotificationService {

    static let shared = NotificationService()

    // MARK: - Observable state

    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    var categoryNotificationsEnabled: Bool = UserDefaults.standard.bool(forKey: Keys.categoryEnabled) {
        didSet { UserDefaults.standard.set(categoryNotificationsEnabled, forKey: Keys.categoryEnabled) }
    }

    var subscribedCategories: Set<String> = Set(
        UserDefaults.standard.stringArray(forKey: Keys.subscribedCategories) ?? []
    ) {
        didSet { UserDefaults.standard.set(Array(subscribedCategories), forKey: Keys.subscribedCategories) }
    }

    var rsvpRemindersEnabled: Bool = UserDefaults.standard.bool(forKey: Keys.rsvpReminders) {
        didSet { UserDefaults.standard.set(rsvpRemindersEnabled, forKey: Keys.rsvpReminders) }
    }

    var notificationRadiusMiles: Double = {
        let stored = UserDefaults.standard.double(forKey: Keys.radiusMiles)
        return stored == 0 ? 10.0 : stored
    }() {
        didSet { UserDefaults.standard.set(notificationRadiusMiles, forKey: Keys.radiusMiles) }
    }

    // MARK: - Private

    private enum Keys {
        static let categoryEnabled      = "notif_categoryEnabled"
        static let subscribedCategories = "notif_subscribedCategories"
        static let rsvpReminders        = "notif_rsvpReminders"
        static let radiusMiles          = "notif_radiusMiles"
    }

    private let center = UNUserNotificationCenter.current()

    private init() {
        Task { await refreshAuthorizationStatus() }
    }

    // MARK: - Authorization

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            return granted
        } catch {
            await refreshAuthorizationStatus()
            return false
        }
    }

    // MARK: - Category notifications

    func scheduleCategoryNotification(for event: Event, userLocation: CLLocation?) {
        print("🔔 scheduling category notification for '\(event.title)'")
        print("🔔   categoryNotificationsEnabled: \(categoryNotificationsEnabled)")
        print("🔔   subscribedCategories: \(subscribedCategories)")
        print("🔔   event.category: \(event.category)")
        print("🔔   userLocation: \(userLocation?.description ?? "nil")")
        print("🔔   event.startDate: \(event.startDate), now: \(Date.now), future: \(event.startDate > .now)")
        print("🔔   event.creatorID: \(event.creatorID ?? "nil")")
        print("🔔   current user: \(AuthService.shared.currentIdentity?.userID ?? "nil")")

        print("🔔   passes enabled check: \(categoryNotificationsEnabled)")
        print("🔔   passes category match: \(subscribedCategories.contains(event.category))")
        print("🔔   passes location non-nil: \(userLocation != nil)")
        print("🔔   passes startDate future: \(event.startDate > .now)")

        guard categoryNotificationsEnabled else { print("🔔 ❌ BLOCKED: categoryNotificationsEnabled=false"); return }
        guard subscribedCategories.contains(event.category) else { print("🔔 ❌ BLOCKED: category '\(event.category)' not in \(subscribedCategories)"); return }
        guard event.startDate > .now else { print("🔔 ❌ BLOCKED: event.startDate is not in the future"); return }

        if let userLocation {
            let eventLocation = CLLocation(latitude: event.latitude, longitude: event.longitude)
            let distanceMeters = userLocation.distance(from: eventLocation)
            let radiusMeters = notificationRadiusMiles * 1609.34
            print("🔔   distance to event: \(distanceMeters)m, radius: \(radiusMeters)m, passes: \(distanceMeters <= radiusMeters)")
            guard distanceMeters <= radiusMeters else { print("🔔 ❌ BLOCKED: event \(distanceMeters)m away, radius \(radiusMeters)m"); return }
        } else {
            print("🔔 userLocation nil — skipping distance check, scheduling anyway")
        }

        let creatorID = event.creatorID
        let userID = AuthService.shared.currentIdentity?.userID
        let isOwnEvent = creatorID != nil && creatorID == userID
        print("🔔   own-event check: creatorID=\(creatorID ?? "nil") userID=\(userID ?? "nil") isOwnEvent=\(isOwnEvent)")
        if let creatorID = event.creatorID,
           let userID = AuthService.shared.currentIdentity?.userID,
           creatorID == userID { print("🔔 ❌ BLOCKED: own event"); return }

        let content = UNMutableNotificationContent()
        content.title = "New \(event.category.capitalized) event nearby"
        content.body = "\(event.title) at \(event.locationName)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "category-\(event.id.uuidString)",
            content: content,
            trigger: trigger
        )
        print("🔔 ✅ ALL GUARDS PASSED — scheduling notification id: category-\(event.id.uuidString)")
        Task { try? await center.add(request) }
    }

    // MARK: - RSVP reminders

    func scheduleRSVPReminder(for event: Event) {
        guard rsvpRemindersEnabled else { return }
        let reminderDate = event.startDate.addingTimeInterval(-3600)
        guard reminderDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "Starting soon: \(event.title)"
        content.body = "Heads up — you said you're going to this at \(event.locationName). Starts in 1 hour."
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "rsvp-\(event.id.uuidString)",
            content: content,
            trigger: trigger
        )
        Task { try? await center.add(request) }
    }

    func cancelRSVPReminder(for eventID: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: ["rsvp-\(eventID.uuidString)"])
    }

    func cancelAllPending() {
        center.removeAllPendingNotificationRequests()
    }
}
