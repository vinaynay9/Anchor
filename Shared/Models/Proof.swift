import Foundation

public struct Proof: Identifiable, Codable {
    public let id: UUID
    public let sessionId: UUID
    public let uploaderId: UUID
    public let unlockRequestId: UUID?
    public let fileUrl: URL
    public let thumbnailUrl: URL?
    public let createdAt: Date

    public init(
        id: UUID,
        sessionId: UUID,
        uploaderId: UUID,
        unlockRequestId: UUID?,
        fileUrl: URL,
        thumbnailUrl: URL?,
        createdAt: Date
    ) {
        self.id = id
        self.sessionId = sessionId
        self.uploaderId = uploaderId
        self.unlockRequestId = unlockRequestId
        self.fileUrl = fileUrl
        self.thumbnailUrl = thumbnailUrl
        self.createdAt = createdAt
    }
    
    public enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case uploaderId = "uploader_id"
        case unlockRequestId = "unlock_request_id"
        case fileUrl = "file_url"
        case thumbnailUrl = "thumbnail_url"
        case createdAt = "created_at"
    }
}

// MARK: - API DTOs
public struct ProofDTO: Codable {
    public let id: String
    public let sessionId: String
    public let uploaderId: String?
    public let unlockRequestId: String?
    public let fileUrl: String
    public let thumbnailUrl: String?
    public let createdAt: String
    
    public func toProof() -> Proof? {
        let formatter = ISO8601DateFormatter()
        guard let uuid = UUID(uuidString: id),
              let sessionIdUUID = UUID(uuidString: sessionId),
              let fileURL = URL(string: fileUrl),
              let createdAtDate = formatter.date(from: createdAt) else {
            return nil
        }
        
        // uploaderId is required, but make it optional in DTO for backward compatibility
        guard let uploaderIdString = uploaderId,
              let uploaderIdUUID = UUID(uuidString: uploaderIdString) else {
            return nil
        }
        
        let unlockRequestIdUUID = unlockRequestId.flatMap { UUID(uuidString: $0) }
        let thumbnailURL = thumbnailUrl.flatMap { URL(string: $0) }
        
        return Proof(
            id: uuid,
            sessionId: sessionIdUUID,
            uploaderId: uploaderIdUUID,
            unlockRequestId: unlockRequestIdUUID,
            fileUrl: fileURL,
            thumbnailUrl: thumbnailURL,
            createdAt: createdAtDate
        )
    }
}
