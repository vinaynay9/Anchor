import Foundation

struct Proof: Identifiable, Codable {
    let id: UUID
    let sessionId: UUID
    let unlockRequestId: UUID?
    let fileUrl: URL
    let thumbnailUrl: URL?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case unlockRequestId = "unlock_request_id"
        case fileUrl = "file_url"
        case thumbnailUrl = "thumbnail_url"
        case createdAt = "created_at"
    }
}

// MARK: - API DTOs
struct ProofDTO: Codable {
    let id: String
    let sessionId: String
    let unlockRequestId: String?
    let fileUrl: String
    let thumbnailUrl: String?
    let createdAt: String
    
    func toProof() -> Proof? {
        let formatter = ISO8601DateFormatter()
        guard let uuid = UUID(uuidString: id),
              let sessionIdUUID = UUID(uuidString: sessionId),
              let fileURL = URL(string: fileUrl),
              let createdAtDate = formatter.date(from: createdAt) else {
            return nil
        }
        
        let unlockRequestIdUUID = unlockRequestId.flatMap { UUID(uuidString: $0) }
        let thumbnailURL = thumbnailUrl.flatMap { URL(string: $0) }
        
        return Proof(
            id: uuid,
            sessionId: sessionIdUUID,
            unlockRequestId: unlockRequestIdUUID,
            fileUrl: fileURL,
            thumbnailUrl: thumbnailURL,
            createdAt: createdAtDate
        )
    }
}

