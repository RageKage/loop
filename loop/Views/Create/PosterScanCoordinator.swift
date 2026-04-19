import Foundation
import SwiftData
import SwiftUI

// MARK: - PosterScanCoordinator

@Observable @MainActor
final class PosterScanCoordinator: Identifiable {
    enum Phase {
        case privacyDisclosure
        case capturing
        case scanning(UIImage)
        case reviewing(ExtractedEvent, UIImage)
        case failed(String)
        case rateLimited(resetAt: Date)
        case offline(imageData: Data)
    }

    nonisolated let id = UUID()
    var phase: Phase

    private let rateLimiter = RateLimiter()
    private let networkMonitor = NetworkMonitor()
    private var scanTask: Task<Void, Never>?

    init() {
        let privacyAccepted = UserDefaults.standard.bool(forKey: "hasAcceptedScanPrivacy")
        phase = privacyAccepted ? .capturing : .privacyDisclosure
    }

    func acceptPrivacy() {
        UserDefaults.standard.set(true, forKey: "hasAcceptedScanPrivacy")
        phase = .capturing
    }

    func submitImage(_ data: Data) {
        guard networkMonitor.isOnline else {
            phase = .offline(imageData: data)
            return
        }
        guard rateLimiter.canScan else {
            let reset = rateLimiter.nextResetAt ?? Date().addingTimeInterval(24 * 3600)
            phase = .rateLimited(resetAt: reset)
            return
        }
        rateLimiter.recordScan()

        guard let preview = UIImage(data: data) else {
            phase = .failed("Couldn't read the image.")
            return
        }
        phase = .scanning(preview)

        scanTask = Task {
            guard let taskImage = UIImage(data: data) else {
                phase = .failed("Couldn't read the image.")
                return
            }
            do {
                let extracted = try await ClaudeVisionService.extractEvent(from: data)
                phase = .reviewing(extracted, taskImage)
            } catch is CancellationError {
                // cancelScan() already reset phase — nothing to do.
            } catch let error as ClaudeVisionError {
                let message: String
                switch error {
                case .notAnEventPoster:
                    message = "This doesn't look like an event poster. Try a different photo."
                case .refused:
                    message = "Claude declined this event. Loop is for community gatherings, not political organizing."
                default:
                    message = error.localizedDescription
                }
                phase = .failed(message)
            } catch {
                phase = .failed(error.localizedDescription)
            }
        }
    }

    func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        phase = .capturing
    }

    func dismissError() {
        phase = .capturing
    }
}

// MARK: - ScanFlowView

struct ScanFlowView: View {
    let coordinator: PosterScanCoordinator
    let onEventPublished: (String) -> Void
    let onDismiss: () -> Void
    let onEnterManually: () -> Void

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        switch coordinator.phase {
        case .privacyDisclosure:
            privacyGateView
        case .capturing:
            PosterCaptureView(
                onCapture: { data in coordinator.submitImage(data) },
                onCancel: { onDismiss() }
            )
        case .scanning(let image):
            ScanningView(image: image, onCancel: { coordinator.cancelScan() })
        case .reviewing(let extracted, _):
            NavigationStack {
                CreateEventFormView(prefill: extracted, onPublished: { title in
                    onEventPublished(title)
                })
            }
        case .failed(let message):
            failedView(message: message)
        case .rateLimited(let resetAt):
            rateLimitedView(resetAt: resetAt)
        case .offline(let imageData):
            offlineView(imageData: imageData)
        }
    }

    // MARK: - Phase views

    @ViewBuilder
    private var privacyGateView: some View {
        Color(.systemBackground)
            .ignoresSafeArea()
            .sheet(isPresented: .constant(true)) {
                PrivacyDisclosureView(
                    onAccept: { coordinator.acceptPrivacy() },
                    onCancel: { onDismiss() }
                )
                .presentationDetents([.medium])
                .interactiveDismissDisabled()
            }
    }

    @ViewBuilder
    private func failedView(message: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.orange)
            Text(message)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Try Another Photo") {
                coordinator.dismissError()
            }
            .buttonStyle(.borderedProminent)
            Button("Cancel") {
                onDismiss()
            }
            .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private func rateLimitedView(resetAt: Date) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.orange)
            Text("Daily limit reached")
                .font(.title2)
                .fontWeight(.bold)
            Text("You've used all 20 scans today.")
                .foregroundStyle(.secondary)
            Text("Try again in \(timeUntil(resetAt))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("OK") { onDismiss() }
                .buttonStyle(.borderedProminent)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private func offlineView(imageData: Data) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "wifi.slash")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary)
            Text("Can't scan offline")
                .font(.title2)
                .fontWeight(.bold)
            Text("Poster scanning needs an internet connection.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            VStack(spacing: 12) {
                Button("Save for Later") {
                    let scan = PendingScan(imageData: imageData)
                    modelContext.insert(scan)
                    try? modelContext.save()
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)

                Button("Enter Manually") {
                    onEnterManually()
                }
                .buttonStyle(.bordered)

                Button("Cancel") { onDismiss() }
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - Helpers

    private func timeUntil(_ date: Date) -> String {
        let seconds = max(0, date.timeIntervalSince(Date()))
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
