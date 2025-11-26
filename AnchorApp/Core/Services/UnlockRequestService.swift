import Foundation

// MARK: - Notification Names
extension Notification.Name {
    static let unlockRequestStatusChanged = Notification.Name("unlockRequestStatusChanged")
}

// MARK: - Unlock Request Service Protocol
protocol UnlockRequestServiceProtocol {
    func sendUnlockRequest(sessionId: String, reason: String) async throws
    func cancelUnlockRequest(sessionId: String) async throws
    func getPendingUnlockRequests() async throws -> [UnlockRequest]
    func approveUnlockRequest(requestId: String) async throws
    func denyUnlockRequest(requestId: String) async throws
}

// MARK: - Unlock Request Service
class UnlockRequestService: UnlockRequestServiceProtocol {
    static let shared = UnlockRequestService()
    
    private let apiClient = APIClient.shared
    private let appGroupStorage = AppGroupStorage.shared
    private let sessionService = SessionService.shared
    private let screenTimeService = ScreenTimeService.shared
    
    private init() {}
    
    // MARK: - Send Unlock Request
    func sendUnlockRequest(sessionId: String, reason: String) async throws {
        // Write setPendingUnlockRequest(true)
        appGroupStorage.setPendingUnlockRequest(true)
        
        // Get current user ID
        guard let userIdString = UserDefaults.standard.string(forKey: AppConfig.UserDefaultsKeys.currentUserId),
              let requesterId = UUID(uuidString: userIdString) else {
            throw NSError(domain: "UnlockRequestService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Get session ID as UUID
        guard let sessionIdUUID = UUID(uuidString: sessionId) else {
            throw NSError(domain: "UnlockRequestService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid session ID"])
        }
        
        // Get active session to retrieve partner ID
        guard let activeSession = try await sessionService.getActiveSession(),
              activeSession.id == sessionIdUUID else {
            throw NSError(domain: "UnlockRequestService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Active session not found"])
        }
        
        guard let partnerId = activeSession.accountabilityPartnerId else {
            throw NSError(domain: "UnlockRequestService", code: 400, userInfo: [NSLocalizedDescriptionKey: "No accountability partner for this session"])
        }
        
        // Create unlock request object
        let unlockRequest = UnlockRequest(
            id: UUID(),
            sessionId: sessionIdUUID,
            requesterId: requesterId,
            partnerId: partnerId,
            status: .pending,
            message: reason,
            createdAt: Date(),
            resolvedAt: nil
        )
        
        // POST /unlock-requests
        do {
            try await apiClient.request(.createUnlockRequest(request: unlockRequest))
        } catch {
            // If backend call fails, still keep the pending state
            // The shield extension will read it from AppGroupStorage
            throw error
        }
    }
    
    // MARK: - Cancel Unlock Request
    func cancelUnlockRequest(sessionId: String) async throws {
        // Write setPendingUnlockRequest(false)
        appGroupStorage.setPendingUnlockRequest(false)
        
        // Notify UI
        NotificationCenter.default.post(name: .unlockRequestStatusChanged, object: nil, userInfo: [
            "sessionId": sessionId,
            "action": "cancelled"
        ])
        
        // TODO: Call backend to cancel the request if needed
        // For now, just update local state
    }
    
    // MARK: - Get Pending Unlock Requests
    func getPendingUnlockRequests() async throws -> [UnlockRequest] {
        // GET /unlock-requests/pending
        let dtos: [UnlockRequestDTO] = try await apiClient.request(.getPendingUnlockRequests, responseType: [UnlockRequestDTO].self)
        return dtos.compactMap { $0.toUnlockRequest() }
    }
    
    // MARK: - Approve Unlock Request
    func approveUnlockRequest(requestId: String) async throws {
        // Write setPendingUnlockRequest(false)
        appGroupStorage.setPendingUnlockRequest(false)
        
        // POST /unlock-requests/{id}/approve
        guard let requestIdUUID = UUID(uuidString: requestId) else {
            throw NSError(domain: "UnlockRequestService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid request ID"])
        }
        
        do {
            try await apiClient.request(.approveUnlockRequest(id: requestIdUUID))
        } catch {
            // Continue with local operations even if backend call fails
        }
        
        // Call SessionService.endSession()
        try await sessionService.endSession()
        
        // Call ScreenTimeService.stopBlocking()
        screenTimeService.stopBlocking()
        
        // Notify UI
        NotificationCenter.default.post(name: .unlockRequestStatusChanged, object: nil, userInfo: [
            "requestId": requestId,
            "action": "approved"
        ])
    }
    
    // MARK: - Deny Unlock Request
    func denyUnlockRequest(requestId: String) async throws {
        // Write setPendingUnlockRequest(false)
        appGroupStorage.setPendingUnlockRequest(false)
        
        // POST /unlock-requests/{id}/reject
        guard let requestIdUUID = UUID(uuidString: requestId) else {
            throw NSError(domain: "UnlockRequestService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid request ID"])
        }
        
        do {
            try await apiClient.request(.rejectUnlockRequest(id: requestIdUUID))
        } catch {
            // Continue with local operations even if backend call fails
        }
        
        // Notify UI
        NotificationCenter.default.post(name: .unlockRequestStatusChanged, object: nil, userInfo: [
            "requestId": requestId,
            "action": "denied"
        ])
    }
}

