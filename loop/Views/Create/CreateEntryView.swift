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

            Spacer().frame(minHeight: 80, maxHeight: 100)

            // ── Hero ────────────────────────────────────────────────────────
            VStack(spacing: 24) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.accentColor)
                }

                VStack(spacing: 8) {
                    Text("Snap a Poster")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text("AI reads the details automatically")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
            }

            // ── Primary CTA ──────────────────────────────────────────────────
            Button { coordinator = PosterScanCoordinator() } label: {
                Label("Choose Photo", systemImage: "photo.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)

            // ── "or" divider ─────────────────────────────────────────────────
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(height: 0.5)
                Text("or")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(height: 0.5)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)

            // ── Secondary action ─────────────────────────────────────────────
            NavigationLink {
                CreateEventFormView(onPublished: onEventPublished)
            } label: {
                Label("Enter manually", systemImage: "square.and.pencil")
                    .font(.body)
                    .foregroundStyle(Color.accentColor)
            }

            Spacer()
        }
        .navigationTitle("")
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

}

#Preview {
    NavigationStack {
        CreateEntryView(onEventPublished: { _ in })
    }
    .modelContainer(for: [Event.self, SavedEvent.self, PendingScan.self], inMemory: true)
}
