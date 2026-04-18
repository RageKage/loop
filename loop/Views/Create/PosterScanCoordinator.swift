import SwiftData
import SwiftUI
import UIKit

/// Drives the full "Snap a Poster" flow:
///
///   Privacy gate → Camera/picker → Scanning overlay → Pre-filled form
///   (or error sheet / offline sheet at any step)
///
/// Presented as a full-screen cover from CreateEntryView.
struct PosterScanCoordinator: View {
    let onEventPublished: (String) -> Void
    let onCancel: () -> Void

    /// When set, the coordinator skips capture and scans this image immediately.
    private let preloadedImageData: Data?

    /// Fresh scan from camera / library.
    init(onEventPublished: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.onEventPublished  = onEventPublished
        self.onCancel          = onCancel
        self.preloadedImageData = nil
    }

    /// Queue-replay scan: skip capture, scan a pre-saved image.
    init(imageDataToScan: Data, onEventPublished: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.onEventPublished   = onEventPublished
        self.onCancel           = onCancel
        self.preloadedImageData = imageDataToScan
    }

    @Environment(\.modelContext) private var modelContext

    @State private var phase: ScanPhase = .privacyGate
    @State private var capturedData: Data?
    @State private var scanTask: Task<Void, Never>?
    @State private var extractedEvent: ExtractedEvent?
    @State private var errorMessage: String?
    @State private var showOfflineSheet  = false

    @State private var networkMonitor = NetworkMonitor()
    @State private var rateLimiter    = RateLimiter()

    private enum ScanPhase {
        case privacyGate
        case capture
        case scanning(UIImage)
        case prefillForm(ExtractedEvent, Data)
        case error(String)
    }

    var body: some View {
        Group {
            switch phase {
            case .privacyGate:
                // Transparent host — presents the disclosure as a sheet immediately.
                Color.black.ignoresSafeArea()
                    .sheet(isPresented: .constant(true)) {
                        PrivacyDisclosureView(
                            onContinue: { phase = .capture },
                            onCancel:   onCancel
                        )
                        .interactiveDismissDisabled()
                    }

            case .capture:
                PosterCaptureView(
                    onCapture: { data in
                        guard let image = UIImage(data: data) else { return }
                        capturedData = data
                        beginScan(imageData: data, image: image)
                    },
                    onCancel: onCancel
                )
                .ignoresSafeArea()

            case .scanning(let image):
                ScanningView(posterImage: image, onCancel: {
                    scanTask?.cancel()
                    onCancel()
                })
                .ignoresSafeArea()

            case .prefillForm(let event, let data):
                NavigationStack {
                    CreateEventFormView(
                        prefill: event,
                        posterData: data,
                        onPublished: { title in
                            onEventPublished(title)
                        }
                    )
                }

            case .error(let msg):
                errorScreen(message: msg)
            }
        }
        .sheet(isPresented: $showOfflineSheet) {
            offlineSheet
        }
        .onAppear {
            if let data = preloadedImageData {
                // Queue-replay path: skip privacy gate (already accepted) and capture.
                guard let image = UIImage(data: data) else { onCancel(); return }
                beginScan(imageData: data, image: image)
            } else if UserDefaults.standard.bool(forKey: PrivacyDisclosureView.acceptedKey) {
                phase = .capture
            }
            // else: stays on .privacyGate and presents the disclosure sheet
        }
    }

    // MARK: - Scan orchestration

    private func beginScan(imageData: Data, image: UIImage) {
        guard networkMonitor.isConnected else {
            showOfflineSheet = true
            return
        }
        guard rateLimiter.canScan() else {
            let secs = rateLimiter.secondsUntilReset() ?? 3600
            let hrs  = Int(ceil(secs / 3600))
            phase = .error("You've reached your daily scan limit. Try again in \(hrs) hour\(hrs == 1 ? "" : "s").")
            return
        }
        guard let apiKey = KeychainService.load(), !apiKey.isEmpty else {
            phase = .error(ScanError.noAPIKey.localizedDescription ?? "No API key configured.")
            return
        }

        phase = .scanning(image)
        rateLimiter.recordScan()

        scanTask = Task {
            do {
                let result = try await ClaudeVisionService.shared.extractEvent(from: imageData, apiKey: apiKey)
                guard !Task.isCancelled else { return }
                phase = .prefillForm(result, imageData)
            } catch let err as ScanError {
                guard !Task.isCancelled else { return }
                phase = .error(err.localizedDescription ?? "Something went wrong.")
            } catch {
                guard !Task.isCancelled else { return }
                phase = .error(ScanError.networkError(error).localizedDescription ?? "Something went wrong.")
            }
        }
    }

    // MARK: - Sub-views

    private func errorScreen(message: String) -> some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(.orange)
                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)

                VStack(spacing: 12) {
                    Button("Try Again") { phase = .capture }
                        .buttonStyle(.borderedProminent)

                    Button("Enter Manually") {
                        // Push an empty form inside the same coordinator.
                        phase = .prefillForm(
                            ExtractedEvent(title: "", description: "", startDate: nil,
                                           endDate: nil, recurrenceRule: nil, locationName: "",
                                           address: nil, isFree: true, price: nil,
                                           organizerName: nil, category: .other,
                                           confidence: [:], isEventPoster: true),
                            Data()
                        )
                    }
                    .foregroundStyle(.secondary)

                    Button("Cancel", action: onCancel)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var offlineSheet: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            Image(systemName: "wifi.slash")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("No Internet Connection")
                    .font(.title3).fontWeight(.bold)
                Text("Poster scanning needs an internet connection. You can enter the event manually, or save your poster photo to scan later.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
            }

            VStack(spacing: 12) {
                Button("Enter Manually") {
                    showOfflineSheet = false
                    onCancel()  // dismiss coordinator; caller shows manual form
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)

                Button("Save Photo for Later") {
                    if let data = capturedData {
                        let scan = PendingScan(imageData: data)
                        modelContext.insert(scan)
                    }
                    showOfflineSheet = false
                    onCancel()
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}
