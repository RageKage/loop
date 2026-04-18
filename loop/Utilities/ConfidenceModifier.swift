import SwiftUI

/// Applies a subtle yellow highlight to form fields that ClaudeVisionService
/// returned with low or medium confidence, prompting the user to double-check.
struct ConfidenceHighlight: ViewModifier {
    let needsReview: Bool

    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            content
                .overlay(alignment: .trailing) {
                    if needsReview {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .padding(.trailing, 4)
                    }
                }
            if needsReview {
                Label("Please double-check this", systemImage: "hand.point.up.left")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
    }
}

extension View {
    func confidenceHighlight(needsReview: Bool) -> some View {
        modifier(ConfidenceHighlight(needsReview: needsReview))
    }
}
