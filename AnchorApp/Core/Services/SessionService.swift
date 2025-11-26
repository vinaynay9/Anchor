import Foundation

protocol SessionServiceProtocol {
    func startSession(durationMinutes: Int, selectedFriendIds: [String]) async throws -> LockSession
    func endSession() async throws
    func getActiveSession() async throws -> LockSession?
}

class SessionService: SessionServiceProtocol {
    static let shared = SessionService()
    
    // In-memory storage for temporary implementation
    private var activeSession: LockSession?
    private let userId: UUID
    
    private init() {
        // Get or create a mock user ID for in-memory implementation
        if let userIdString = UserDefaults.standard.string(forKey: AppConfig.UserDefaultsKeys.currentUserId),
           let uuid = UUID(uuidString: userIdString) {
            self.userId = uuid
        } else {
            // Create a temporary UUID for in-memory testing
            self.userId = UUID()
            UserDefaults.standard.set(userId.uuidString, forKey: AppConfig.UserDefaultsKeys.currentUserId)
        }
    }
    
    func startSession(durationMinutes: Int, selectedFriendIds: [String]) async throws -> LockSession {
        // End any existing active session
        if activeSession != nil {
            activeSession = nil
        }
        
        let startTime = Date()
        let durationSeconds = TimeInterval(durationMinutes * 60)
        let endTime = startTime.addingTimeInterval(durationSeconds)
        
        // Convert friend IDs from String to UUID
        let accountabilityPartnerId = selectedFriendIds.first.flatMap { UUID(uuidString: $0) }
        
        let session = LockSession(
            id: UUID(),
            userId: userId,
            status: .active,
            startTime: startTime,
            endTime: endTime,
            appsBlocked: [], // Empty for now, will be populated later
            accountabilityPartnerId: accountabilityPartnerId,
            createdAt: Date()
        )
        
        activeSession = session
        return session
    }
    
    func endSession() async throws {
        guard let session = activeSession else {
            throw NSError(domain: "SessionService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No active session to end"])
        }
        
        // Update session status to completed
        let endedSession = LockSession(
            id: session.id,
            userId: session.userId,
            status: .completed,
            startTime: session.startTime,
            endTime: session.endTime,
            appsBlocked: session.appsBlocked,
            accountabilityPartnerId: session.accountabilityPartnerId,
            createdAt: session.createdAt
        )
        
        activeSession = nil
    }
    
    func getActiveSession() async throws -> LockSession? {
        // Check if active session has expired
        if let session = activeSession,
           let endTime = session.endTime,
           endTime < Date() {
            // Session expired, clear it
            activeSession = nil
            return nil
        }
        
        return activeSession
    }
}

