import Foundation
import UIKit
import Shared

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

protocol ProofServiceProtocol {
    func uploadProof(imageData: Data, sessionId: String) async throws -> Proof
    func fetchProofs(for sessionId: String) async throws -> [Proof]
    func getProof(id: UUID) async throws -> Proof
    func getProofsForUser(userId: UUID) async throws -> [Proof]
}

class ProofService: ProofServiceProtocol {
    static let shared = ProofService()
    
    private let apiClient = APIClient.shared
    
    private init() {}
    
    // MARK: - POST /proofs (multipart)
    
    func uploadProof(imageData: Data, sessionId: String) async throws -> Proof {
        // Validate image data
        guard imageData.count > 0 else {
            throw ProofError.invalidImageData
        }
        
        // Convert sessionId string to UUID for validation
        guard UUID(uuidString: sessionId) != nil else {
            throw ProofError.invalidImageData
        }
        
        // POST /proofs - Upload using multipart/form-data
        let endpoint = APIEndpoint.uploadProof(sessionId: sessionId, imageData: imageData)
        let dto: ProofDTO = try await apiClient.request(endpoint, responseType: ProofDTO.self)
        
        guard let proof = dto.toProof() else {
            throw ProofError.invalidResponse
        }
        
        return proof
    }
    
    // MARK: - Fetch proofs for session
    
    func fetchProofs(for sessionId: String) async throws -> [Proof] {
        // For now, we'll fetch all proofs for the current user
        // In the future, we might have a GET /proofs?session_id={id} endpoint
        guard let userIdString = UserDefaults.standard.string(forKey: AppConfig.UserDefaultsKeys.currentUserId),
              let userId = UUID(uuidString: userIdString) else {
            throw ProofError.networkError(NSError(domain: "ProofService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
        }
        
        // Get all proofs for user and filter by sessionId
        let allProofs = try await getProofsForUser(userId: userId)
        return allProofs.filter { $0.sessionId.uuidString == sessionId }
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

