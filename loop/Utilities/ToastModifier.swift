import SwiftUI

// MARK: - ToastModifier

/// Displays a transient pill-shaped message above the tab bar.
/// The message auto-dismisses after 3 seconds.
///
/// Usage:
///   SomeView()
///       .toast($myOptionalStringBinding)
struct ToastModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text(message)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.82), in: Capsule())
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                    // Sit above the tab bar (≈ 49 pt) with a small gap.
                    .padding(.bottom, 64)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        Task {
                            try? await Task.sleep(for: .seconds(3))
                            withAnimation(.spring(duration: 0.35)) {
                                self.message = nil
                            }
                        }
                    }
                }
            }
            .animation(.spring(duration: 0.35), value: message != nil)
    }
}

extension View {
    func toast(_ message: Binding<String?>) -> some View {
        modifier(ToastModifier(message: message))
    }
}
