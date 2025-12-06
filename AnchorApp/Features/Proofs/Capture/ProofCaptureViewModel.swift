import SwiftUI
import Combine
import UIKit
import Shared

@MainActor
class ProofCaptureViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var uploadComplete = false
    @Published var errorMessage: String?
    
    private let proofService: ProofServiceProtocol
    
    init(proofService: ProofServiceProtocol = ProofService.shared) {
        self.proofService = proofService
    }
    
    func capturePhoto(from image: UIImage) {
        capturedImage = image
        errorMessage = nil
    }
    
    func retakePhoto() {
        capturedImage = nil
        uploadComplete = false
        uploadProgress = 0.0
        errorMessage = nil
    }
    
    func submitProof(sessionId: String) {
        guard let image = capturedImage else { return }
        
        isUploading = true
        uploadProgress = 0.0
        uploadComplete = false
        errorMessage = nil
        
        // Process image: strip EXIF metadata and compress
        guard let imageData = ImageProcessingUtility.processImageForUpload(image) else {
            errorMessage = "Failed to process image for upload"
            isUploading = false
            return
        }
        
        Task {
            // Simulate progress updates during upload
            let progressTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
            var progressCancellable: AnyCancellable?
            
            progressCancellable = progressTimer.sink { [weak self] _ in
                guard let self = self, self.isUploading else {
                    progressCancellable?.cancel()
                    return
                }
                // Gradually increase progress to 90% while uploading
                if self.uploadProgress < 0.9 {
                    self.uploadProgress = min(self.uploadProgress + 0.05, 0.9)
                }
            }
            
            do {
                let proof = try await proofService.uploadProof(imageData: imageData, sessionId: sessionId)
                
                await MainActor.run {
                    progressCancellable?.cancel()
                    self.uploadProgress = 1.0
                    self.isUploading = false
                    self.uploadComplete = true
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    progressCancellable?.cancel()
                    self.isUploading = false
                    self.uploadComplete = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func reset() {
        capturedImage = nil
        isUploading = false
        uploadProgress = 0.0
        uploadComplete = false
        errorMessage = nil
    }
}

