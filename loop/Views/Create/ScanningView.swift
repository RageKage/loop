import SwiftUI

struct ScanningView: View {
    let image: UIImage
    let onCancel: () -> Void

    @State private var pulsing = false

    private let statusMessages = ["Reading the poster…", "Extracting details…", "Almost done…"]

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .opacity(0.3)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "sparkles")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(.white)
                    .scaleEffect(pulsing ? 1.1 : 1.0)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
                            pulsing = true
                        }
                    }

                TimelineView(.periodic(from: .now, by: 1.8)) { context in
                    let index = Int(context.date.timeIntervalSince1970 / 1.8) % statusMessages.count
                    Text(statusMessages[index])
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button { onCancel() } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding(.top, 56)
            .padding(.leading, 20)
        }
    }
}

#Preview {
    ScanningView(image: UIImage(systemName: "photo")!, onCancel: {})
}
