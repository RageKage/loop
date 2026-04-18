import SwiftUI
import PhotosUI

struct PosterCaptureView: View {
    let onCapture: (Data) -> Void
    let onCancel: () -> Void

    @State private var pickerItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var showPicker = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let image = selectedImage {
                imagePreview(image)
            } else {
                emptyPrompt
            }

            Button { onCancel() } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding(.top, 56)
            .padding(.leading, 20)
        }
        .ignoresSafeArea()
        .photosPicker(isPresented: $showPicker, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                }
            }
        }
    }

    private var emptyPrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64, weight: .ultraLight))
                .foregroundStyle(.secondary)

            Text("Pick a poster")
                .font(.title2.bold())

            Text("Choose a photo of an event poster from your library")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Choose from Library") {
                showPicker = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private func imagePreview(_ image: UIImage) -> some View {
        ZStack(alignment: .bottom) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .ignoresSafeArea()

            HStack(spacing: 16) {
                Button("Retake") {
                    selectedImage = nil
                    pickerItem = nil
                }
                .buttonStyle(.bordered)
                .tint(.white)

                Button("Scan This Poster") {
                    guard let data = image.jpegData(compressionQuality: 0.9) else { return }
                    onCapture(data)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.bottom, 48)
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    PosterCaptureView(onCapture: { _ in }, onCancel: {})
}
