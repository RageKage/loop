import CoreLocation
import SwiftUI

/// A single row in the event list. Shows category icon, title, venue,
/// date/time, distance from the user, and a free/paid badge.
struct EventListRowView: View {
    let event: Event
    let userLocation: CLLocation

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            // Category icon tile
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(event.categoryEnum.color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: event.categoryEnum.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(event.categoryEnum.color)
            }

            // Main text
            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Text(event.locationName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            // Right-hand badges
            VStack(alignment: .trailing, spacing: 4) {
                // Free / paid badge
                Text(event.isFree ? "Free" : String(format: "$%.0f", event.price ?? 0))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(event.isFree ? Color.green : Color.primary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(event.isFree ? Color.green.opacity(0.12) : Color(.systemGray5))
                    .clipShape(Capsule())

                // Trust badge
                if EventTrustSignal.isVerified(event) {
                    Label("Verified", systemImage: "checkmark.seal.fill")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                } else {
                    Text("Community")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                // Distance
                Text(event.distanceString(from: userLocation))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
