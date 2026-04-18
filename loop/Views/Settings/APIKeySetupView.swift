import SwiftUI

/// Sheet for entering or updating the Claude API key stored in Keychain.
/// Accessible from Settings → Developer → Claude API Key.
struct APIKeySetupView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var keyText:      String = ""
    @State private var showKey:      Bool   = false
    @State private var saveError:    String?
    @State private var showSuccess:  Bool   = false

    private var hasExistingKey: Bool { KeychainService.load() != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Group {
                            if showKey {
                                TextField("sk-ant-...", text: $keyText)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            } else {
                                SecureField("sk-ant-...", text: $keyText)
                            }
                        }
                        Button {
                            showKey.toggle()
                        } label: {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Claude API Key")
                } footer: {
                    Text("Keys start with sk-ant-. Get yours at console.anthropic.com. Stored in the iOS Keychain — never transmitted to Loop's servers.")
                }

                if let err = saveError {
                    Section {
                        Label(err, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                }

                if hasExistingKey {
                    Section {
                        Button("Remove API Key", role: .destructive) {
                            KeychainService.delete()
                            keyText = ""
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(hasExistingKey ? "Update API Key" : "Add API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveKey() }
                        .fontWeight(.semibold)
                        .disabled(keyText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                // Pre-fill with masked existing key so user knows one is set.
                if let existing = KeychainService.load() {
                    keyText = existing
                }
            }
            .alert("Key saved", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("Your Claude API key has been saved to the Keychain.")
            }
        }
    }

    private func saveKey() {
        let trimmed = keyText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        do {
            try KeychainService.save(trimmed)
            showSuccess = true
        } catch {
            saveError = error.localizedDescription
        }
    }
}
