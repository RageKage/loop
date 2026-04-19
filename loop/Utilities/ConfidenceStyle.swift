import SwiftUI

struct ConfidenceModifier: ViewModifier {
    let level: String?

    func body(content: Content) -> some View {
        Group {
            if level == "low" || level == "medium" {
                VStack(alignment: .leading, spacing: 2) {
                    content
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.orange.opacity(0.6), lineWidth: 0.5)
                        )
                    Text("Please double-check this")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            } else {
                content
            }
        }
    }
}

extension View {
    func confidence(_ level: String?) -> some View {
        modifier(ConfidenceModifier(level: level))
    }
}
