import SwiftUI

/// The map annotation bubble shown for each event.
/// Color-coded by category with the matching SF Symbol inside.
struct EventPinView: View {
    let category: EventCategory

    var body: some View {
        ZStack {
            Circle()
                .fill(category.color)
                .frame(width: 34, height: 34)
                .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
            Image(systemName: category.systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    HStack(spacing: 8) {
        ForEach(EventCategory.allCases, id: \.self) { cat in
            EventPinView(category: cat)
        }
    }
    .padding()
}
