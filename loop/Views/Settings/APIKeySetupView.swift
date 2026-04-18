import SwiftUI

struct APIKeySetupView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var keyInput = ""
    @State private var errorMessage: String? = nil
    @State private var isRevealed = false
    private var hasExistingKey: Bool { KeychainService.load() != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Loop uses Claude to read event posters. Get a key at console.anthropic.com — $5 in free credits covers ~1,400 scans.")
                        .foregroundStyle(.secondary)
                }

                Section {
                    HStack {
                        Group {
                            if isRevealed {
                                TextField("sk-ant-...", text: $keyInput)
                            } else {
                                SecureField("sk-ant-...", text: $keyInput)
                            }
                        }
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                        Button {
                            isRevealed.toggle()
                        } label: {
                            Image(systemName: isRevealed ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    if let error = errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                Section {
                    Button("Save") {
                        save()
                    }
                }

                if hasExistingKey {
                    Section {
                        Button("Remove Key", role: .destructive) {
                            removeKey()
                        }
                    }
                }
            }
            .navigationTitle("Claude API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let trimmed = keyInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            errorMessage = "API key cannot be empty."
            return
        }
        guard trimmed.hasPrefix("sk-ant-") else {
            errorMessage = "Key must start with \"sk-ant-\"."
            return
        }
        do {
            try KeychainService.save(trimmed)
            dismiss()
        } catch {
            errorMessage = "Failed to save key. Try again."
        }
    }

    private func removeKey() {
        try? KeychainService.delete()
        dismiss()
    }
}

#Preview {
    APIKeySetupView()
}
