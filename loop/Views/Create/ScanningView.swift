import SwiftUI
import UIKit

/// Full-screen scanning overlay shown while ClaudeVisionService is working.
/// Displays the poster dimmed in the background, a pulsing logo, rotating
/// status text, and a cancel button.
struct ScanningView: View {
    let posterImage: UIImage
    let onCancel: () -> Void

    @State private var statusIndex  = 0
    @State private var dotCount     = 0
    @State private var isAnimating  = false

    private let statusMessages = [
        "Reading the poster",
        "Extracting details",
        "Almost done",
    ]

    var body: some View {
        ZStack {
            // Dimmed poster background
            Image(uiImage: posterImage)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .blur(radius: 6)
                .overlay(Color.black.opacity(0.6).ignoresSafeArea())

            VStack(spacing: 28) {
                // Pulsing scan icon
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.15), lineWidth: 2)
                        .frame(width: 96, height: 96)
                        .scaleEffect(isAnimating ? 1.4 : 1.0)
                        .opacity(isAnimating ? 0 : 0.6)

                    Image(systemName: "sparkles")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(.white)
                }
                .animation(.easeOut(duration: 1.2).repeatForever(autoreverses: false), value: isAnimating)

                // Rotating status text
                Text(statusMessages[statusIndex] + String(repeating: ".", count: dotCount + 1))
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.4), value: statusIndex)
            }

            // Cancel button
            VStack {
                HStack {
                    Spacer()
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.black.opacity(0.45), in: Circle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                Spacer()
            }
        }
        .onAppear {
            isAnimating = true
            startCycling()
        }
    }

    private func startCycling() {
        // Advance dot count every 0.6 s; roll status message every 2 s.
        let dotTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            dotCount = (dotCount + 1) % 3
        }
        let msgTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation {
                statusIndex = (statusIndex + 1) % statusMessages.count
            }
        }
        // Timers self-invalidate when the view disappears because the view's
        // lifetime controls the cycle — acceptable for a short-lived overlay.
        RunLoop.main.add(dotTimer, forMode: .common)
        RunLoop.main.add(msgTimer, forMode: .common)
    }
}

#Preview {
    ScanningView(posterImage: UIImage(systemName: "photo")!, onCancel: {})
}
