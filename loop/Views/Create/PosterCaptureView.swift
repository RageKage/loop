import AVFoundation
import PhotosUI
import SwiftUI

/// Handles both live camera capture and photo-library picker.
/// After the user confirms their choice, calls `onCapture` with the JPEG data.
/// Falls back to the Photos picker automatically on simulator (no camera hardware).
struct PosterCaptureView: View {
    let onCapture: (Data) -> Void
    let onCancel:  () -> Void

    @State private var showCamera       = false
    @State private var showPicker       = false
    @State private var capturedImage:  UIImage? = nil
    @State private var pickerItem:     PhotosPickerItem? = nil
    @State private var cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)

    var body: some View {
        Group {
            if let image = capturedImage {
                previewScreen(image: image)
            } else {
                chooseSourceScreen
            }
        }
        .photosPicker(isPresented: $showPicker, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                capturedImage = image
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerRepresentable(onCapture: { image in
                capturedImage = image
                showCamera    = false
            }, onCancel: {
                showCamera = false
                onCancel()
            })
            .ignoresSafeArea()
        }
    }

    // MARK: - Source picker

    private var chooseSourceScreen: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 64, weight: .ultraLight))
                    .foregroundStyle(.white)

                Text("Aim at the poster.\nKeep it flat and well-lit.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.85))

                VStack(spacing: 12) {
                    if cameraAvailable {
                        Button {
                            showCamera = true
                        } label: {
                            Label("Open Camera", systemImage: "camera")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.white)
                                .foregroundStyle(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }

                    Button {
                        showPicker = true
                    } label: {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.white.opacity(0.15))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 32)
            }

            VStack {
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.black.opacity(0.4), in: Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                Spacer()
            }
        }
    }

    // MARK: - Preview / confirm

    private func previewScreen(image: UIImage) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .ignoresSafeArea()

            VStack {
                Spacer()
                HStack(spacing: 20) {
                    Button {
                        capturedImage = nil
                        pickerItem    = nil
                    } label: {
                        Text("Retake")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.black.opacity(0.55))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.3)))
                    }

                    Button {
                        guard let jpeg = image.jpegData(compressionQuality: 0.9) else { return }
                        onCapture(jpeg)
                    } label: {
                        Text("Scan This Poster")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - UIImagePickerController wrapper

private struct CameraPickerRepresentable: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    let onCancel:  () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture, onCancel: onCancel) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType    = .camera
        picker.delegate      = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        let onCancel:  () -> Void
        init(onCapture: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onCapture = onCapture; self.onCancel = onCancel
        }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage { onCapture(img) }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { onCancel() }
    }
}
