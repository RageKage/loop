import SwiftUI

struct PrivacyDisclosureView: View {
    let onAccept: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)

            Image(systemName: "sparkles")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.blue)
                .padding(.bottom, 12)

            Text("How scanning works")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 4)

            Text("Before your first scan")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 28)

            VStack(spacing: 16) {
                infoRow(
                    icon: "paperplane",
                    title: "Photo sent to Claude",
                    detail: "Your poster photo is sent to Anthropic's Claude API to extract event details."
                )
                infoRow(
                    icon: "trash",
                    title: "Not stored on our servers",
                    detail: "Photos aren't retained after processing."
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                Button("Continue") {
                    onAccept()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 24)

                Button("Cancel") {
                    onCancel()
                }
                .foregroundStyle(.secondary)
            }
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private func infoRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .fontWeight(.semibold)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    PrivacyDisclosureView(onAccept: {}, onCancel: {})
}
