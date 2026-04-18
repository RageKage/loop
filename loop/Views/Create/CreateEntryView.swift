import SwiftUI

/// The two-button landing screen inside the Create tab.
/// "Manual Entry" pushes the full form.
/// "Snap a Poster" launches the poster-scan coordinator as a full-screen cover.
struct CreateEntryView: View {
    let onEventPublished: (String) -> Void

    @State private var showScanFlow     = false
    @State private var showManualForm   = false
    @State private var showOfflineSnack = false

    @State private var networkMonitor = NetworkMonitor()
    @State private var rateLimiter    = RateLimiter()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // ── Hero ────────────────────────────────────────────────────────
            VStack(spacing: 10) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(.blue)

                Text("Add an Event")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("How would you like to add it?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // ── Option cards ─────────────────────────────────────────────────
            VStack(spacing: 12) {
                NavigationLink {
                    CreateEventFormView(onPublished: onEventPublished)
                } label: {
                    entryCard(
                        icon: "square.and.pencil",
                        title: "Manual Entry",
                        subtitle: "Fill in the event details yourself",
                        badge: nil
                    )
                }
                .buttonStyle(.plain)

                Button {
                    showScanFlow = true
                } label: {
                    entryCard(
                        icon: "camera.viewfinder",
                        title: "Snap a Poster",
                        subtitle: "Claude reads the details automatically",
                        badge: nil
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .navigationTitle("Create")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showScanFlow) {
            PosterScanCoordinator(
                onEventPublished: { title in
                    showScanFlow = false
                    onEventPublished(title)
                },
                onCancel: { showScanFlow = false }
            )
        }
    }

    // MARK: - Card helper

    private func entryCard(
        icon: String,
        title: String,
        subtitle: String,
        badge: String?
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let badge {
                Text(badge)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    NavigationStack {
        CreateEntryView(onEventPublished: { _ in })
    }
}
