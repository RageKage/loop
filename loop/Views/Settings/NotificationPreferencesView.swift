import SwiftUI
import UserNotifications

struct NotificationPreferencesView: View {
    @Bindable private var service = NotificationService.shared

    var body: some View {
        Form {
            authorizationSection

            if service.authorizationStatus == .authorized
                || service.authorizationStatus == .provisional
                || service.authorizationStatus == .ephemeral {
                categorySection
                rsvpSection
            }
        }
        .navigationTitle("Notification Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .task { await service.refreshAuthorizationStatus() }
    }

    // MARK: - Sections

    @ViewBuilder
    private var authorizationSection: some View {
        Section {
            switch service.authorizationStatus {
            case .notDetermined:
                Button("Enable Notifications") {
                    Task { await service.requestAuthorizationIfNeeded() }
                }
            case .denied:
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notifications are off in iOS Settings. Open Settings to enable.")
                        .foregroundStyle(.red)
                        .font(.subheadline)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            case .authorized, .provisional, .ephemeral:
                Label("Notifications are on.", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            @unknown default:
                EmptyView()
            }
        }
    }

    private var categorySection: some View {
        Section {
            Toggle("New events near me", isOn: $service.categoryNotificationsEnabled)

            if service.categoryNotificationsEnabled {
                ForEach(EventCategory.allCases, id: \.rawValue) { category in
                    let isSelected = service.subscribedCategories.contains(category.rawValue)
                    Button {
                        if isSelected {
                            service.subscribedCategories.remove(category.rawValue)
                        } else {
                            service.subscribedCategories.insert(category.rawValue)
                        }
                    } label: {
                        HStack {
                            Label(category.displayName, systemImage: category.systemImage)
                                .foregroundStyle(.primary)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                }
            }
        } header: {
            Text("Event Discovery")
        } footer: {
            Text("Get a heads-up when someone posts a new event in these categories within 10 miles.")
        }
    }

    private var rsvpSection: some View {
        Section {
            Toggle("Reminder before events I'm going to", isOn: $service.rsvpRemindersEnabled)
        } header: {
            Text("RSVP Reminders")
        } footer: {
            Text("Get a notification 1 hour before the event starts.")
        }
    }
}

#Preview {
    NavigationStack {
        NotificationPreferencesView()
    }
}
