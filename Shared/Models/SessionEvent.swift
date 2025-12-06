import Foundation

enum SessionEventType: String, Codable {
    case sessionStarted
    case proofSubmitted
    case unlockRequested
    case unlockApproved
    case unlockDenied
    case sessionEnded
}

struct SessionEvent: Identifiable, Codable {
    let id: UUID
    let type: SessionEventType
    let timestamp: Date
    let metadata: [String: String]? // optional bundleId, reason, etc.
    
    init(
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

