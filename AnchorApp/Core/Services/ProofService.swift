import Foundation
import UIKit

enum ProofError: Error {
    case imageCaptureFailed
    case uploadFailed
    case invalidImageData
    case invalidSessionId
    case invalidResponse
}

protocol ProofServiceProtocol {
    func uploadProof(imageData: Data, sessionId: String) async throws -> Proof
    func fetchProofs(for sessionId: String) async throws -> [Proof]
}

class ProofService: ProofServiceProtocol {
    static let shared = ProofService()
    
    private let apiClient: APIClient
    
    init(apiClient: APIClient = APIClient.shared) {
        self.apiClient = apiClient
    }
    
    func uploadProof(imageData: Data, sessionId: String) async throws -> Proof {
        guard UUID(uuidString: sessionId) != nil else {
            throw ProofError.invalidSessionId
        }
        
        let endpoint = APIEndpoint.uploadProof(sessionId: sessionId, imageData: imageData)
        let dto: ProofDTO = try await apiClient.request(endpoint, responseType: ProofDTO.self)
        
        guard let proof = dto.toProof() else {
            throw ProofError.invalidResponse
        }
        
        return proof
    }
    
    func fetchProofs(for sessionId: String) async throws -> [Proof] {
        guard UUID(uuidString: sessionId) != nil else {
            throw ProofError.invalidSessionId
        }
        
        let endpoint = APIEndpoint.getProofs(sessionId: sessionId)
        let dtos: [ProofDTO] = try await apiClient.request(endpoint, responseType: [ProofDTO].self)
        
        return dtos.compactMap { $0.toProof() }
    }
}

