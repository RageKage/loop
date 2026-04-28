import SwiftUI

struct AboutView: View {
    private var shortVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 6) {
                    Text("Loop")
                        .font(.title2.weight(.semibold))
                    Text("Free community events")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .listRowBackground(Color.clear)
            }

            Section {
                LabeledContent("Version", value: "\(shortVersion) (\(buildNumber))")
            }

            Section {
                Link(destination: URL(string: "https://github.com/RageKage/loop")!) {
                    Label("View on GitHub", systemImage: "arrow.up.right.square")
                }
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
