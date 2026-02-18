import Foundation

public enum SessionEventType: String, Codable, Hashable {
    case sessionStarted
    case proofSubmitted
    case unlockRequested
    case unlockApproved
    case unlockDenied
    case sessionEnded
}

public struct SessionEvent: Identifiable, Codable, Hashable {
    public let id: UUID
    public let type: SessionEventType
    public let timestamp: Date
    public let metadata: [String: String]? // optional bundleId, reason, etc.
    
    public init(
        id: UUID = UUID(),
        type: SessionEventType,
        timestamp: Date = Date(),
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.metadata = metadata
    }
}
