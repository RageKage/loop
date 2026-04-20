import SwiftData
import SwiftUI

struct ReportEventSheet: View {
    let event: Event

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedReason: ReportReason = .inappropriate
    @State private var details = ""
    @State private var showSuccess = false

    private let maxDetails = 500

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(event.title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Reporting")
                }

                Section("Reason") {
                    Picker("Reason", selection: $selectedReason) {
                        ForEach(ReportReason.allCases) { reason in
                            Text(reason.rawValue).tag(reason)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Additional details (optional)") {
                    TextEditor(text: $details)
                        .frame(minHeight: 80)
                        .onChange(of: details) {
                            if details.count > maxDetails {
                                details = String(details.prefix(maxDetails))
                            }
                        }
                    Text("\(details.count)/\(maxDetails)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                Section {
                    Button(action: submitReport) {
                        Text("Submit Report")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                    .tint(.blue)
                }
            }
            .navigationTitle("Report Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Report submitted — thanks for helping keep Loop safe.", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func submitReport() {
        let report = EventReport(
            eventID: event.id,
            eventTitle: event.title,
            reason: selectedReason.rawValue,
            details: details.trimmingCharacters(in: .whitespacesAndNewlines),
            reporterUserID: AuthService.shared.currentIdentity?.userID
        )
        modelContext.insert(report)
        showSuccess = true
    }
}
