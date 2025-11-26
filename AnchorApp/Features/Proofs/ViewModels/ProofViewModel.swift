import SwiftUI
import UIKit

class ProofViewModel: ObservableObject {
    @Published var proofs: [Proof] = []
    @Published var isUploading: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let proofService: ProofServiceProtocol
    
    init(proofService: ProofServiceProtocol = ProofService.shared) {
        self.proofService = proofService
    }
    
    func loadProofs(for sessionId: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let loadedProofs = try await proofService.fetchProofs(for: sessionId)
                await MainActor.run {
                    self.proofs = loadedProofs
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func upload(image: UIImage, for sessionId: String) {
        isUploading = true
        errorMessage = nil
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Failed to convert image to JPEG data"
            isUploading = false
            return
        }
        
        Task {
            do {
                let proof = try await proofService.uploadProof(imageData: imageData, sessionId: sessionId)
                await MainActor.run {
                    self.proofs.append(proof)
                    self.isUploading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isUploading = false
                }
            }
        }
    }
}

