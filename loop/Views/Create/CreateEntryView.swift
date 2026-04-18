import SwiftUI

/// The two-button landing screen inside the Create tab.
/// Tapping "Manual Entry" pushes the full form; "Snap a Poster" shows a
/// coming-soon alert until Phase 4 wires up the Vision/AI pipeline.
struct CreateEntryView: View {
    /// Called by the pushed form after a successful publish, so the parent
    /// CreateView can surface a toast without cross-tab state management.
    let onEventPublished: (String) -> Void

    @State private var showSnapAlert = false

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

                Button { showSnapAlert = true } label: {
                    entryCard(
                        icon: "camera.viewfinder",
                        title: "Snap a Poster",
                        subtitle: "AI reads the details automatically",
                        badge: "Phase 4"
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .navigationTitle("Create")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Coming in Phase 4", isPresented: $showSnapAlert) {
            Button("Got it", role: .cancel) {}
        } message: {
            Text("Poster scanning with AI is coming in Phase 4. Use Manual Entry for now to publish your event.")
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
