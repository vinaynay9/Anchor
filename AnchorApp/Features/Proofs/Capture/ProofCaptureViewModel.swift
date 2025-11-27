import SwiftUI
import Combine
import UIKit

@MainActor
class ProofCaptureViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var uploadComplete = false
    @Published var errorMessage: String?
    
    private var uploadTimer: Timer?
    private let uploadDuration: TimeInterval = 1.5
    private let toastManager = ToastManager.shared
    
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
    
    func startUpload() {
        guard capturedImage != nil else { return }
        
        isUploading = true
        uploadProgress = 0.0
        uploadComplete = false
        errorMessage = nil
        
        // Simulate upload progress
        let startTime = Date()
        uploadTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / self.uploadDuration, 1.0)
            
            Task { @MainActor in
                self.uploadProgress = progress
                
                if progress >= 1.0 {
                    timer.invalidate()
                    self.isUploading = false
                    self.uploadComplete = true
                    self.toastManager.showSuccess("Upload Complete")
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
        uploadTimer?.invalidate()
        uploadTimer = nil
    }
    
    deinit {
        uploadTimer?.invalidate()
    }
}

