import SwiftUI
import UIKit

class ProofViewModel: ObservableObject {
    @Published var proofs: [Proof] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let proofService = ProofService.shared
    
    func uploadProof(image: UIImage, sessionId: UUID, unlockRequestId: UUID?) {
        isLoading = true
        
        Task {
            do {
                let proof = try await proofService.uploadProof(
                    image: image,
                    sessionId: sessionId,
                    unlockRequestId: unlockRequestId
                )
                
                await MainActor.run {
                    self.proofs.append(proof)
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
    
    func loadProofs(sessionId: UUID) {
        isLoading = true
        
        Task {
            do {
                let loadedProofs = try await proofService.getProofs(sessionId: sessionId)
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
}

