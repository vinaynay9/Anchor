import SwiftUI
import UIKit
import Shared

struct CaptureProofView: View {
    let sessionId: String
    @StateObject private var viewModel = ProofViewModel()
    @State private var showingImagePicker = false
    @State private var capturedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 400)
                
                if viewModel.isUploading {
                    ProgressView("Uploading...")
                        .padding()
                } else {
                    Button(action: {
                        viewModel.upload(image: image, for: sessionId)
                    }) {
                        Text("Use Photo")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding()
                }
            } else {
                Button(action: {
                    showingImagePicker = true
                }) {
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 50))
                        Text("Take Photo")
                            .font(AppTypography.bodyBold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.primary)
                    .cornerRadius(Theme.cornerRadius)
                }
                .padding()
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $capturedImage)
        }
        .navigationTitle("Capture Proof")
        .onChange(of: viewModel.isUploading) { isUploading in
            if !isUploading && viewModel.errorMessage == nil && capturedImage != nil {
                dismiss()
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

