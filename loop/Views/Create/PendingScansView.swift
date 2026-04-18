import SwiftData
import SwiftUI

/// Sheet that processes the offline-saved poster queue one scan at a time.
/// Opened from the banner in CreateView when pending scans exist and the
/// device is back online.
struct PendingScansView: View {
    let onEventPublished: (String) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @Query(sort: \PendingScan.createdAt) private var pendingScans: [PendingScan]

    @State private var currentScan:     PendingScan?
    @State private var showScanFlow     = false
    @State private var scanTask:        Task<Void, Never>?
    @State private var isScanning       = false
    @State private var errorMessage:    String?

    private var rateLimiter  = RateLimiter()

    var body: some View {
        NavigationStack {
            Group {
                if pendingScans.isEmpty {
                    ContentUnavailableView(
                        "All caught up",
                        systemImage: "checkmark.circle",
                        description: Text("No posters waiting to scan.")
                    )
                } else {
                    List {
                        if let msg = errorMessage {
                            Section {
                                Label(msg, systemImage: "exclamationmark.triangle")
                                    .foregroundStyle(.orange)
                                    .font(.subheadline)
                            }
                        }

                        Section {
                            ForEach(pendingScans) { scan in
                                HStack {
                                    if let image = UIImage(data: scan.imageData) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 56, height: 56)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemGray5))
                                            .frame(width: 56, height: 56)
                                            .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Saved poster")
                                            .fontWeight(.medium)
                                        Text(scan.createdAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Button("Scan") {
                                        processScan(scan)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                    .disabled(isScanning)
                                }
                            }
                            .onDelete { offsets in
                                for i in offsets { modelContext.delete(pendingScans[i]) }
                            }
                        } footer: {
                            Text("Swipe left to delete a saved poster without scanning.")
                        }
                    }
                }
            }
            .navigationTitle("Saved Posters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .fullScreenCover(isPresented: $showScanFlow) {
            if let scan = currentScan {
                PosterScanCoordinator(
                    imageDataToScan: scan.imageData,
                    onEventPublished: { title in
                        modelContext.delete(scan)
                        showScanFlow = false
                        onEventPublished(title)
                        dismiss()
                    },
                    onCancel: { showScanFlow = false }
                )
            }
        }
    }

    private func processScan(_ scan: PendingScan) {
        guard rateLimiter.canScan() else {
            let secs = rateLimiter.secondsUntilReset() ?? 3600
            let hrs  = Int(ceil(secs / 3600))
            errorMessage = "Daily scan limit reached. Try again in \(hrs) hour\(hrs == 1 ? "" : "s")."
            return
        }
        errorMessage = nil
        currentScan  = scan
        showScanFlow = true
    }
}

// MARK: - Banner

/// Small strip shown at the top of the Create tab when pending scans exist and
/// the device is online. Tapping it opens PendingScansView.
struct PendingScansBanner: View {
    let count: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "clock.badge.exclamationmark")
                    .foregroundStyle(.orange)
                Text("\(count) poster\(count == 1 ? "" : "s") waiting to scan")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemOrange).opacity(0.12))
        }
        .buttonStyle(.plain)
    }
}
