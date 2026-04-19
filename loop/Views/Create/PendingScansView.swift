import SwiftData
import SwiftUI

struct PendingScansView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PendingScan.createdAt) private var pendingScans: [PendingScan]

    let onScanNow: (Data) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if pendingScans.isEmpty {
                    ContentUnavailableView(
                        "No Pending Scans",
                        systemImage: "photo.badge.checkmark",
                        description: Text("Posters saved while offline appear here.")
                    )
                } else {
                    List {
                        ForEach(pendingScans) { scan in
                            pendingScanRow(scan)
                        }
                    }
                }
            }
            .navigationTitle("Pending Scans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func pendingScanRow(_ scan: PendingScan) -> some View {
        HStack(spacing: 12) {
            if let uiImage = UIImage(data: scan.imageData) {
                Image(uiImage: uiImage)
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

            VStack(alignment: .leading, spacing: 3) {
                Text("Poster")
                    .fontWeight(.semibold)
                Text(scan.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    let data = scan.imageData
                    modelContext.delete(scan)
                    try? modelContext.save()
                    dismiss()
                    onScanNow(data)
                } label: {
                    Text("Scan Now")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button(role: .destructive) {
                    modelContext.delete(scan)
                    try? modelContext.save()
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    PendingScansView(onScanNow: { _ in })
        .modelContainer(for: PendingScan.self, inMemory: true)
}
