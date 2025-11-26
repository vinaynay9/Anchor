import Foundation
import UIKit

enum ProofError: LocalizedError {
    case imageConversionFailed
    case invalidImageData
    case invalidResponse
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image to JPEG data"
        case .invalidImageData:
            return "Invalid image data provided"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

class ProofService {
    static let shared = ProofService()
    
    private let apiClient = APIClient.shared
    
    private init() {}
    
    // MARK: - POST /proofs (multipart)
    
    func uploadProof(sessionId: UUID, image: UIImage) async throws -> Proof {
        // Convert UIImage to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ProofError.imageConversionFailed
        }
        
        // Validate image data
        guard imageData.count > 0 else {
            throw ProofError.invalidImageData
        }
        
        // POST /proofs - Upload using multipart/form-data
        let endpoint = APIEndpoint.uploadProof(sessionId: sessionId.uuidString, imageData: imageData)
        let dto: ProofDTO = try await apiClient.request(endpoint, responseType: ProofDTO.self)
        
        guard let proof = dto.toProof() else {
            throw ProofError.invalidResponse
        }
        
        return proof
    }
    
    // MARK: - GET /proofs/{id}
    
    func getProof(id: UUID) async throws -> Proof {
        let endpoint = APIEndpoint.getProof(id: id)
        let dto: ProofDTO = try await apiClient.request(endpoint, responseType: ProofDTO.self)
        
        guard let proof = dto.toProof() else {
            throw ProofError.invalidResponse
        }
        
        return proof
    }
    
    // MARK: - GET /proofs/user/{id}
    
    func getProofsForUser(userId: UUID) async throws -> [Proof] {
        let endpoint = APIEndpoint.getProofsForUser(userId: userId)
        let dtos: [ProofDTO] = try await apiClient.request(endpoint, responseType: [ProofDTO].self)
        
        return dtos.compactMap { $0.toProof() }
    }
}

