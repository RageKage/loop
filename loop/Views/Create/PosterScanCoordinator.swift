import Foundation
import SwiftUI

// MARK: - PosterScanCoordinator

@Observable @MainActor
final class PosterScanCoordinator: Identifiable {
    enum Phase {
        case capturing
        case scanning(UIImage)
        case reviewing(ExtractedEvent, UIImage)
        case failed(String)
    }

    nonisolated let id = UUID()
    var phase: Phase = .capturing
    private var scanTask: Task<Void, Never>?

    func submitImage(_ data: Data) {
        guard let preview = UIImage(data: data) else {
            phase = .failed("Couldn't read the image.")
            return
        }
        phase = .scanning(preview)

        scanTask = Task {
            // Re-create UIImage inside the task from Sendable Data to avoid
            // capturing the non-Sendable UIImage across the async boundary.
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
                case .refused(_):
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

    var body: some View {
        switch coordinator.phase {
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
}
