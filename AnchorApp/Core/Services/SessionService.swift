import Foundation

protocol SessionServiceProtocol {
    func createSession(
        appsBlocked: [String],
        accountabilityPartnerId: UUID?,
        duration: TimeInterval?
    ) async throws -> LockSession
    func getActiveSession() async throws -> LockSession?
    func getSession(id: UUID) async throws -> LockSession
    func endSession(id: UUID) async throws
    func updateSessionStatus(id: UUID, status: SessionStatus) async throws -> LockSession
}

class SessionService: SessionServiceProtocol {
    static let shared = SessionService()
    
    private let apiClient = APIClient.shared
    
    func createSession(
        appsBlocked: [String],
        accountabilityPartnerId: UUID?,
        duration: TimeInterval?
    ) async throws -> LockSession {
        guard let userIdString = UserDefaults.standard.string(forKey: AppConfig.UserDefaultsKeys.currentUserId),
              let userId = UUID(uuidString: userIdString) else {
            throw APIError.unauthorized
        }
        
        let session = LockSession(
            id: UUID(),
            userId: userId,
            status: .active,
            startTime: Date(),
            endTime: duration.map { Date().addingTimeInterval($0) },
            appsBlocked: appsBlocked,
            accountabilityPartnerId: accountabilityPartnerId,
            createdAt: Date()
        )
        
        // TODO: Implement API response parsing
        // let dto: LockSessionDTO = try await apiClient.request(.createSession(session: session), responseType: LockSessionDTO.self)
        // return dto.toLockSession() ?? session
        
        return session
    }
    
    func getActiveSession() async throws -> LockSession? {
        // TODO: Implement API response parsing
        return nil
    }
    
    func getSession(id: UUID) async throws -> LockSession {
        // TODO: Implement API response parsing
        throw APIError.unknown
    }
    
    func endSession(id: UUID) async throws {
        try await apiClient.request(.endSession(id: id))
    }
    
    func updateSessionStatus(id: UUID, status: SessionStatus) async throws -> LockSession {
        // TODO: Implement API response parsing
        throw APIError.unknown
    }
}

