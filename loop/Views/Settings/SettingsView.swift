import SwiftUI
import UIKit

struct SettingsView: View {
    @State private var showAPIKeySetup = false
    @State private var apiKeyRefreshTrigger = 0
    @State private var isTesting = false
    @State private var testResult: String? = nil
    @State private var showResult = false

    private var apiKeyConfigured: Bool {
        let _ = apiKeyRefreshTrigger
        return KeychainService.load() != nil
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Location") {
                    Label("Location Permission", systemImage: "location")
                        .foregroundStyle(.secondary)
                }

                Section("Notifications") {
                    Label("Notification Preferences", systemImage: "bell")
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button {
                        showAPIKeySetup = true
                    } label: {
                        if apiKeyConfigured {
                            Text("Claude API Key (configured)")
                                .foregroundStyle(.tint)
                        } else {
                            Text("Set Claude API Key")
                                .foregroundStyle(.red)
                        }
                    }

                    Button {
                        runAPITest()
                    } label: {
                        if isTesting {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 4)
                                Text("Testing…")
                            }
                        } else {
                            Label("Test Claude API", systemImage: "flask")
                        }
                    }
                    .disabled(isTesting)

                    Button("Print Key Fingerprint (debug)") {
                        printKeyFingerprint()
                        testResult = "Check Xcode console"
                        showResult = true
                    }
                } header: {
                    Text("Developer")
                } footer: {
                    Text("Required for poster scanning. Coming in the next update.")
                }

                Section("About") {
                    LabeledContent("App", value: "Loop")
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Build", value: "Phase 1 — Foundation")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAPIKeySetup, onDismiss: {
                apiKeyRefreshTrigger += 1
            }) {
                APIKeySetupView()
            }
            .alert("API Test Result", isPresented: $showResult) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(testResult ?? "")
            }
        }
    }

    private func runAPITest() {
        guard KeychainService.loadWithDevFallback() != nil else {
            testResult = "Set an API key first."
            showResult = true
            return
        }

        isTesting = true

        Task {
            let imageData = makePosterTestImage()
            do {
                let event = try await ClaudeVisionService.extractEvent(from: imageData)
                let title = event.title ?? "(no title)"
                let category = event.category ?? "(no category)"
                let titleConf = event.confidence?.title ?? "?"
                let dateConf = event.confidence?.date ?? "?"
                testResult = "Title: \(title)\nCategory: \(category)\nConfidence — title: \(titleConf), date: \(dateConf)"
            } catch {
                testResult = error.localizedDescription
            }
            isTesting = false
            showResult = true
        }
    }

    private func printKeyFingerprint() {
        guard let key = KeychainService.loadWithDevFallback() else {
            print("🔑 No key saved")
            print("🔑 Source: none")
            return
        }
        if KeychainService.load() != nil {
            print("🔑 Source: Keychain")
        } else {
            #if DEBUG
            print("🔑 Source: DevAPIKey.swift (DEBUG)")
            #else
            print("🔑 Source: none")
            #endif
        }
        print("🔑 Key length: \(key.count)")
        print("🔑 First 8: \(String(key.prefix(8)))")
        print("🔑 Last 8: \(String(key.suffix(8)))")
        print("🔑 Starts with sk-ant-: \(key.hasPrefix("sk-ant-"))")
        print("🔑 Contains whitespace/newlines: \(key.rangeOfCharacter(from: .whitespacesAndNewlines) != nil)")
    }

    private func makePosterTestImage() -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 400))
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 600, height: 400))

            let lines = [
                ("Lake Harriet Run Club", UIFont.boldSystemFont(ofSize: 36), 60.0),
                ("Every Saturday 7am", UIFont.systemFont(ofSize: 28), 130.0),
                ("Free", UIFont.systemFont(ofSize: 24), 190.0),
                ("Organized by Minneapolis Runners", UIFont.systemFont(ofSize: 20), 240.0),
            ]

            let style = NSMutableParagraphStyle()
            style.alignment = .center

            for (text, font, y) in lines {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.black,
                    .paragraphStyle: style,
                ]
                let rect = CGRect(x: 20, y: y, width: 560, height: 50)
                text.draw(in: rect, withAttributes: attrs)
            }
        }
        return image.jpegData(compressionQuality: 0.9) ?? Data()
    }
}

#Preview {
    SettingsView()
}
