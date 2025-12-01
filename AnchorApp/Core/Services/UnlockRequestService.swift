import Foundation
import Shared

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
    
    /// Strongly-typed errors for unlock request operations
    private enum UnlockRequestError: Error {
        /// Thrown when the provided session ID cannot be converted to a valid UUID
        case invalidSessionId
        /// Wraps underlying errors from backend API calls
        case backendFailure(underlying: Error)
    }
    
    private let apiClient = APIClient.shared
    private let appGroupStorage = AppGroupStorage.shared
    private let sessionService: SessionServiceProtocol
    private let screenTimeService: ScreenTimeServiceProtocol
    private let notificationService: NotificationServiceProtocol
    
    init(
        sessionService: SessionServiceProtocol = SessionService.shared,
        screenTimeService: ScreenTimeServiceProtocol = ScreenTimeService.shared,
        notificationService: NotificationServiceProtocol = NotificationService.shared
    ) {
        self.sessionService = sessionService
        self.screenTimeService = screenTimeService
        self.notificationService = notificationService
    }
    
    
    // MARK: - Send Unlock Request
    func sendUnlockRequest(sessionId: String, reason: String) async throws {
        // Write setPendingUnlockRequest(true)
        appGroupStorage.setPendingUnlockRequest(true)
        
        // Get current user ID
        guard let userIdString = UserDefaults.standard.string(forKey: AppConfig.UserDefaultsKeys.currentUserId),
              let requesterId = UUID(uuidString: userIdString) else {
            throw AnchorAPIError.unauthorized
        }
        
        // Get session ID as UUID
        guard let sessionIdUUID = UUID(uuidString: sessionId) else {
            throw AnchorAPIError.unknown
        }
        
        // Get active session to retrieve partner ID
        guard let activeSession = try await sessionService.getActiveSession(),
              activeSession.id == sessionIdUUID else {
            throw AnchorAPIError.notFound
        }
        
        guard let partnerId = activeSession.accountabilityPartnerId else {
            throw AnchorAPIError.unknown
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
        // Convert sessionId string to UUID
        guard let sessionIdUUID = UUID(uuidString: sessionId) else {
            throw UnlockRequestError.invalidSessionId
        }
        
        // Call backend to cancel the request
        do {
            try await apiClient.request(.cancelUnlockRequest(sessionId: sessionIdUUID))
        } catch {
            // Wrap backend error but continue with local operations
            // This ensures UI state is updated even if network fails
            let wrappedError = UnlockRequestError.backendFailure(underlying: error)
            // Error is logged/wrapped but not thrown to maintain current behavior
        }
        
        // Write setPendingUnlockRequest(false)
        appGroupStorage.setPendingUnlockRequest(false)
        
        // Notify UI
        NotificationCenter.default.post(name: .unlockRequestStatusChanged, object: nil, userInfo: [
            "sessionId": sessionId,
            "action": "cancelled"
        ])
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
            throw AnchorAPIError.unknown
        }
        
        do {
            try await apiClient.request(.approveUnlockRequest(id: requestIdUUID))
        } catch {
            // Continue with local operations even if backend call fails
        }
        
        // Call SessionService.endSession()
        try await sessionService.endSession()
        
        // Call ScreenTimeService.stopBlocking()
        await screenTimeService.stopBlocking()
        
        // Clear session state from AppGroupStorage
        appGroupStorage.clearSessionState()
        
        // Notify UI
        NotificationCenter.default.post(name: .unlockRequestStatusChanged, object: nil, userInfo: [
            "requestId": requestId,
            "action": "approved"
        ])
        
        // Send notification to requester
        await notificationService.notifyUnlockRequestApproved(requestId: requestId)
    }
    
    // MARK: - Deny Unlock Request
    func denyUnlockRequest(requestId: String) async throws {
        // Write setPendingUnlockRequest(false)
        appGroupStorage.setPendingUnlockRequest(false)
        
        // POST /unlock-requests/{id}/reject
        guard let requestIdUUID = UUID(uuidString: requestId) else {
            throw AnchorAPIError.unknown
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
        
        // Send notification to requester
        await notificationService.notifyUnlockRequestRejected(requestId: requestId)
    }
}

