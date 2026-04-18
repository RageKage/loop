import SwiftUI

/// Shown exactly once before the first poster scan.
/// Acceptance stored in UserDefaults; never shown again after "Continue."
struct PrivacyDisclosureView: View {
    static let acceptedKey = "loop.scanPrivacyAccepted"

    let onContinue: () -> Void
    let onCancel:   () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 24)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 32))
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("How scanning works")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Before your first scan")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 16) {
                        disclosureRow(
                            icon: "iphone.and.arrow.forward",
                            title: "Photo sent to Claude",
                            body: "Your poster photo is sent to Anthropic's Claude API to extract the event title, date, location, and other details."
                        )
                        disclosureRow(
                            icon: "trash",
                            title: "Not stored on our servers",
                            body: "Loop has no backend. Photos go directly from your device to Anthropic's API and are not retained after processing."
                        )
                        disclosureRow(
                            icon: "checkmark.shield",
                            title: "You stay in control",
                            body: "You review every extracted detail before publishing. Nothing is posted automatically."
                        )
                    }

                    Text("By tapping Continue, you agree that your photo may be processed by Anthropic in accordance with their [Privacy Policy](https://www.anthropic.com/privacy).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 24)
            }

            VStack(spacing: 10) {
                Button {
                    UserDefaults.standard.set(true, forKey: Self.acceptedKey)
                    onContinue()
                } label: {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button("Cancel", action: onCancel)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    private func disclosureRow(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.blue)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).fontWeight(.semibold)
                Text(body).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}
