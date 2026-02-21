import Foundation
import Shared

/// Service for persisting data locally for offline support
/// Uses App Group directory for file storage and UserDefaults for metadata
class PersistenceService {
    static let shared = PersistenceService()
    
    private let appGroupIdentifier = AppGroupStorage.appGroupIdentifier
    private let fileManager = FileManager.default
    private static var didLogAppGroupFailure = false
    
    /// Base directory for App Group storage
    private var appGroupDirectory: URL? {
        if let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            return containerURL
        }
        logAppGroupFailureOnce("⚠️ [PersistenceService] Failed to get App Group container URL")
        #if DEBUG
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        #else
        assertionFailure("App Group container unavailable in release build.")
        return nil
        #endif
    }
    
    /// Directory for storing cached sessions
    private var sessionsDirectory: URL? {
        guard let base = appGroupDirectory else { return nil }
        let dir = base.appendingPathComponent("sessions", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    /// Directory for storing queued unlock requests
    private var unlockRequestsDirectory: URL? {
        guard let base = appGroupDirectory else { return nil }
        let dir = base.appendingPathComponent("unlock_requests", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    /// Directory for storing pending proof photos
    private var proofsDirectory: URL? {
        guard let base = appGroupDirectory else { return nil }
        let dir = base.appendingPathComponent("proofs", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    /// Directory for storing session timeline events
    private var timelineDirectory: URL? {
        guard let base = appGroupDirectory else { return nil }
        let dir = base.appendingPathComponent("timeline", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    private init() {}

    private func logAppGroupFailureOnce(_ message: String) {
        guard !Self.didLogAppGroupFailure else { return }
        Self.didLogAppGroupFailure = true
        print(message)
    }
    
    // MARK: - LockSession Persistence
    
    /// Saves a LockSession to local storage
    func saveSession(_ session: LockSession) throws {
        guard let dir = sessionsDirectory else {
            throw PersistenceError.directoryNotFound
        }
        
        let fileURL = dir.appendingPathComponent("\(session.id.uuidString).json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(session)
        try data.write(to: fileURL)
        
        print("✅ [PersistenceService] Saved session: \(session.id.uuidString)")
    }
    
    /// Loads a LockSession from local storage
    func loadSession(sessionId: UUID) -> LockSession? {
        guard let dir = sessionsDirectory else { return nil }
        
        let fileURL = dir.appendingPathComponent("\(sessionId.uuidString).json")
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(LockSession.self, from: data)
    }
    
    /// Loads the active session from local storage
    func loadActiveSession() -> LockSession? {
        guard let dir = sessionsDirectory else { return nil }
        
        // Try to find active session by checking all session files
        guard let files = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        for fileURL in files where fileURL.pathExtension == "json" {
            guard let data = try? Data(contentsOf: fileURL),
                  let session = try? decoder.decode(LockSession.self, from: data),
                  session.status == .active,
                  let endTime = session.endTime,
                  endTime > Date() else {
                continue
            }
            return session
        }
        
        return nil
    }
    
    /// Deletes a session from local storage
    func deleteSession(sessionId: UUID) {
        guard let dir = sessionsDirectory else { return }
        let fileURL = dir.appendingPathComponent("\(sessionId.uuidString).json")
        try? fileManager.removeItem(at: fileURL)
    }
    
    // MARK: - UnlockRequest Queue Persistence
    
    /// Saves a queued unlock request to local storage
    func saveQueuedUnlockRequest(_ request: UnlockRequest) throws {
        guard let dir = unlockRequestsDirectory else {
            throw PersistenceError.directoryNotFound
        }
        
        let fileURL = dir.appendingPathComponent("\(request.id.uuidString).json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(request)
        try data.write(to: fileURL)
        
        print("✅ [PersistenceService] Saved queued unlock request: \(request.id.uuidString)")
    }
    
    /// Loads all queued unlock requests from local storage
    func loadQueuedUnlockRequests() -> [UnlockRequest] {
        guard let dir = unlockRequestsDirectory else { return [] }
        
        guard let files = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
            return []
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        var requests: [UnlockRequest] = []
        for fileURL in files where fileURL.pathExtension == "json" {
            guard let data = try? Data(contentsOf: fileURL),
                  let request = try? decoder.decode(UnlockRequest.self, from: data),
                  request.status == .queued else {
                continue
            }
            requests.append(request)
        }
        
        return requests.sorted { $0.createdAt < $1.createdAt }
    }
    
    /// Deletes a queued unlock request from local storage
    func deleteQueuedUnlockRequest(requestId: UUID) {
        guard let dir = unlockRequestsDirectory else { return }
        let fileURL = dir.appendingPathComponent("\(requestId.uuidString).json")
        try? fileManager.removeItem(at: fileURL)
        print("🗑️ [PersistenceService] Deleted queued unlock request: \(requestId.uuidString)")
    }
    
    // MARK: - Proof Photo Persistence
    
    /// Saves a proof photo temporarily for later upload
    func savePendingProofPhoto(_ imageData: Data, proofId: UUID, sessionId: UUID) throws -> URL {
        guard let dir = proofsDirectory else {
            throw PersistenceError.directoryNotFound
        }
        
        let fileURL = dir.appendingPathComponent("\(proofId.uuidString).jpg")
        try imageData.write(to: fileURL)
        
        // Save metadata
        let metadata = PendingProofMetadata(
            proofId: proofId,
            sessionId: sessionId,
            createdAt: Date(),
            filePath: fileURL.path
        )
        let metadataURL = dir.appendingPathComponent("\(proofId.uuidString).metadata.json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let metadataData = try encoder.encode(metadata)
        try metadataData.write(to: metadataURL)
        
        print("✅ [PersistenceService] Saved pending proof photo: \(proofId.uuidString)")
        return fileURL
    }
    
    /// Loads all pending proof photos from local storage
    func loadPendingProofs() -> [PendingProofMetadata] {
        guard let dir = proofsDirectory else { return [] }
        
        guard let files = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
            return []
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        var proofs: [PendingProofMetadata] = []
        for fileURL in files where fileURL.pathExtension == "json" && fileURL.lastPathComponent.contains(".metadata") {
            guard let data = try? Data(contentsOf: fileURL),
                  let metadata = try? decoder.decode(PendingProofMetadata.self, from: data) else {
                continue
            }
            proofs.append(metadata)
        }
        
        return proofs.sorted { $0.createdAt < $1.createdAt }
    }
    
    /// Loads image data for a pending proof
    func loadPendingProofImage(proofId: UUID) -> Data? {
        guard let dir = proofsDirectory else { return nil }
        let fileURL = dir.appendingPathComponent("\(proofId.uuidString).jpg")
        return try? Data(contentsOf: fileURL)
    }
    
    /// Deletes a pending proof photo and its metadata
    func deletePendingProof(proofId: UUID) {
        guard let dir = proofsDirectory else { return }
        let imageURL = dir.appendingPathComponent("\(proofId.uuidString).jpg")
        let metadataURL = dir.appendingPathComponent("\(proofId.uuidString).metadata.json")
        try? fileManager.removeItem(at: imageURL)
        try? fileManager.removeItem(at: metadataURL)
        print("🗑️ [PersistenceService] Deleted pending proof: \(proofId.uuidString)")
    }
    
    // MARK: - Session Timeline Events Persistence
    
    /// Saves a session timeline event to local storage
    func saveTimelineEvent(_ event: SessionEvent, sessionId: UUID) throws {
        guard let dir = timelineDirectory else {
            throw PersistenceError.directoryNotFound
        }
        
        // Store sessionId in metadata for filtering
        var metadata = event.metadata ?? [:]
        metadata["sessionId"] = sessionId.uuidString
        let eventWithSessionId = SessionEvent(
            id: event.id,
            type: event.type,
            timestamp: event.timestamp,
            metadata: metadata
        )
        
        let fileURL = dir.appendingPathComponent("\(event.id.uuidString).json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(eventWithSessionId)
        try data.write(to: fileURL)
    }
    
    /// Loads timeline events for a session
    func loadTimelineEvents(sessionId: UUID) -> [SessionEvent] {
        guard let dir = timelineDirectory else { return [] }
        
        guard let files = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
            return []
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        var events: [SessionEvent] = []
        for fileURL in files where fileURL.pathExtension == "json" {
            guard let data = try? Data(contentsOf: fileURL),
                  let event = try? decoder.decode(SessionEvent.self, from: data),
                  event.metadata?["sessionId"] == sessionId.uuidString else {
                continue
            }
            events.append(event)
        }
        
        return events.sorted { $0.timestamp < $1.timestamp }
    }
    
    /// Deletes timeline events for a session
    func deleteTimelineEvents(sessionId: UUID) {
        guard let dir = timelineDirectory else { return }
        
        guard let files = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
            return
        }
        
        for fileURL in files where fileURL.pathExtension == "json" {
            guard let data = try? Data(contentsOf: fileURL),
                  let event = try? JSONDecoder().decode(SessionEvent.self, from: data),
                  event.metadata?["sessionId"] == sessionId.uuidString else {
                continue
            }
            try? fileManager.removeItem(at: fileURL)
        }
    }
    
    // MARK: - Cleanup
    
    /// Cleans up old cached data (proofs older than 7 days, completed sessions older than 30 days)
    func cleanupOldData() {
        cleanupOldProofs()
        cleanupOldSessions()
    }
    
    private func cleanupOldProofs() {
        guard proofsDirectory != nil else { return }
        let cutoffDate = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days ago
        
        let pendingProofs = loadPendingProofs()
        for proof in pendingProofs where proof.createdAt < cutoffDate {
            deletePendingProof(proofId: proof.proofId)
        }
    }
    
    private func cleanupOldSessions() {
        guard let dir = sessionsDirectory else { return }
        let cutoffDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
        
        guard let files = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
            return
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        for fileURL in files where fileURL.pathExtension == "json" {
            guard let data = try? Data(contentsOf: fileURL),
                  let session = try? decoder.decode(LockSession.self, from: data),
                  session.status != .active,
                  session.createdAt < cutoffDate else {
                continue
            }
            deleteSession(sessionId: session.id)
        }
    }
}

// MARK: - Supporting Types

struct PendingProofMetadata: Codable {
    let proofId: UUID
    let sessionId: UUID
    let createdAt: Date
    let filePath: String
}


enum PersistenceError: LocalizedError {
    case directoryNotFound
    case encodingFailed
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .directoryNotFound:
            return "App Group directory not found"
        case .encodingFailed:
            return "Failed to encode data"
        case .decodingFailed:
            return "Failed to decode data"
        }
    }
}
