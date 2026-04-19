import SwiftData
import SwiftUI

struct CreateEntryView: View {
    let onEventPublished: (String) -> Void

    @State private var coordinator: PosterScanCoordinator? = nil
    @State private var networkMonitor = NetworkMonitor()
    @State private var showPendingScans = false
    @State private var enterManuallyFromScan = false

    @Query(sort: \PendingScan.createdAt) private var pendingScans: [PendingScan]

    var body: some View {
        VStack(spacing: 0) {
            // Pending scans banner
            if !pendingScans.isEmpty && networkMonitor.isOnline {
                pendingScansBanner
            }

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

                Button { coordinator = PosterScanCoordinator() } label: {
                    entryCard(
                        icon: "camera.viewfinder",
                        title: "Snap a Poster",
                        subtitle: "AI reads the details automatically",
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
        .navigationDestination(isPresented: $enterManuallyFromScan) {
            CreateEventFormView(onPublished: onEventPublished)
        }
        .sheet(isPresented: $showPendingScans) {
            PendingScansView { imageData in
                showPendingScans = false
                let c = PosterScanCoordinator()
                coordinator = c
                c.submitImage(imageData)
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { coordinator != nil },
            set: { if !$0 { coordinator = nil } }
        )) {
            if let c = coordinator {
                ScanFlowView(
                    coordinator: c,
                    onEventPublished: { title in
                        coordinator = nil
                        onEventPublished(title)
                    },
                    onDismiss: { coordinator = nil },
                    onEnterManually: {
                        coordinator = nil
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(350))
                            enterManuallyFromScan = true
                        }
                    }
                )
            }
        }
    }

    // MARK: - Subviews

    private var pendingScansBanner: some View {
        Button { showPendingScans = true } label: {
            HStack {
                Image(systemName: "clock.badge.exclamationmark")
                    .foregroundStyle(.orange)
                Text("\(pendingScans.count) poster\(pendingScans.count == 1 ? "" : "s") waiting to scan")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemYellow).opacity(0.15))
        }
        .buttonStyle(.plain)
    }

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
    .modelContainer(for: [Event.self, SavedEvent.self, PendingScan.self], inMemory: true)
}
