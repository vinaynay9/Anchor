import Foundation
import Shared

// MARK: - Unlock Request Service Protocol
protocol UnlockRequestServiceProtocol {
    // New methods matching requirements
    func submitUnlockRequest(session: LockSession, appBundleId: String, reason: String?) async throws -> UnlockRequest
    func approveUnlockRequest(_ request: UnlockRequest) async throws -> UnlockRequest
    func denyUnlockRequest(_ request: UnlockRequest) async throws -> UnlockRequest
    func fetchPendingRequests() async throws -> [UnlockRequest]
    
    // Legacy methods (kept for backward compatibility)
    func sendUnlockRequest(sessionId: String, reason: String) async throws
    func cancelUnlockRequest(sessionId: String) async throws
    func getPendingUnlockRequests() async throws -> [UnlockRequest]
    func approveUnlockRequest(requestId: String) async throws
    func denyUnlockRequest(requestId: String) async throws
}

// MARK: - Unlock Request Service
// MARK: - Service Rewrite Decision
// UnlockRequestService is REWRITTEN to respect plan-centric unlock policies (self/friend/quorum).
class UnlockRequestService: UnlockRequestServiceProtocol {
    static let shared = UnlockRequestService()
    
    /// Strongly-typed errors for unlock request operations
    private enum UnlockRequestError: Error {
        /// Thrown when the provided session ID cannot be converted to a valid UUID
        case invalidSessionId
        /// Wraps underlying errors from backend API calls
        case backendFailure(underlying: Error)
        /// Thrown when a goal-gated unlock is requested but goals are incomplete
        case goalRequirementNotMet
        /// Thrown when quorum is required (group unlock flow)
        case quorumRequired
    }
    
    private let apiClient = APIClient.shared
    private let appGroupStorage = AppGroupStorage.shared
    private let sessionService: SessionServiceProtocol
    private let screenTimeService: ScreenTimeServiceProtocol
    private let notificationService: NotificationServiceProtocol
    private let persistenceService = PersistenceService.shared
    private let networkMonitor = NetworkMonitor.shared
    private let goalService: GoalServiceProtocol
    private let quorumService: QuorumServiceProtocol
    
    init(
        sessionService: SessionServiceProtocol = SessionService.shared,
        screenTimeService: ScreenTimeServiceProtocol = ScreenTimeService.shared,
        notificationService: NotificationServiceProtocol = NotificationService.shared,
        goalService: GoalServiceProtocol = GoalService.shared,
        quorumService: QuorumServiceProtocol = QuorumService.shared
    ) {
        self.sessionService = sessionService
        self.screenTimeService = screenTimeService
        self.notificationService = notificationService
        self.goalService = goalService
        self.quorumService = quorumService
    }
    
    /// Helper to add event to active session
    private func addEventToSession(_ event: SessionEvent) {
        if let sessionService = sessionService as? SessionService {
            sessionService.addEventToActiveSession(event)
        }
    }
    
    
    // MARK: - New Methods (Matching Requirements)
    
    /// Submits an unlock request for a specific app during a session.
    /// - Parameters:
    ///   - session: The active lock session
    ///   - appBundleId: The bundle identifier of the app to unlock
    ///   - reason: Optional reason for the unlock request
    /// - Returns: The created unlock request
    func submitUnlockRequest(session: LockSession, appBundleId: String, reason: String?) async throws -> UnlockRequest {
        LoggerService.shared.logInfo("Submitting unlock request for app: \(appBundleId), session: \(session.id.uuidString)", category: "Network")
        
        // Enforcement: goal-gated unlocks must complete goals before any unlock flow.
        if session.goalRequirement != .none, !goalService.areAllGoalsCompleted() {
            appGroupStorage.setShieldState(
                ShieldState(
                    reason: .goalNotApproved,
                    sessionId: session.id,
                    planType: session.lockPlanType,
                    unlockPolicy: session.unlockPolicy,
                    goalRequirement: session.goalRequirement
                )
            )
            throw UnlockRequestError.goalRequirementNotMet
        }
        
        // Enforcement: quorum-based unlocks do not use individual unlock requests.
        if session.unlockPolicy == .quorum {
            if let quorum = session.quorumState {
                appGroupStorage.setShieldState(
                    ShieldState(
                        reason: .waitingForQuorum,
                        sessionId: session.id,
                        planType: session.lockPlanType,
                        unlockPolicy: session.unlockPolicy,
                        quorumState: quorum
                    )
                )
            }
            throw UnlockRequestError.quorumRequired
        }
        
        // Self-unlock: approve immediately without partner flow.
        if session.unlockPolicy == .selfUnlock {
            appGroupStorage.setPendingUnlockRequest(false)
            appGroupStorage.setUnlockAllowed(bundleId: appBundleId)
            let approved = UnlockRequest(
                id: UUID(),
                sessionId: session.id,
                requesterId: session.userId,
                partnerId: session.userId,
                status: .approved,
                message: reason,
                appBundleId: appBundleId,
                createdAt: Date(),
                resolvedAt: Date()
            )
            return approved
        }
        
        // Write setPendingUnlockRequest(true)
        appGroupStorage.setPendingUnlockRequest(true)
        
        // Get current user ID
        guard let userIdString = UserDefaults.standard.string(forKey: AppConfig.UserDefaultsKeys.currentUserId),
              let requesterId = UUID(uuidString: userIdString) else {
            throw AnchorAPIError.unauthorized
        }
        
        guard let partnerId = session.accountabilityPartnerId else {
            throw AnchorAPIError.unknown
        }
        
        // Create unlock request object
        let unlockRequest = UnlockRequest(
            id: UUID(),
            sessionId: session.id,
            requesterId: requesterId,
            partnerId: partnerId,
            status: .pending,
            message: reason,
            appBundleId: appBundleId,
            createdAt: Date(),
            resolvedAt: nil
        )
        
        // POST /unlock-requests
        do {
            let responseDTO: UnlockRequestDTO = try await apiClient.request(.createUnlockRequest(request: unlockRequest), responseType: UnlockRequestDTO.self)
            guard let createdRequest = responseDTO.toUnlockRequest() else {
                throw AnchorAPIError.decodingError(NSError(domain: "UnlockRequestService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode unlock request from API"]))
            }
            
            // Add unlock requested event
            var metadata: [String: String] = [:]
            metadata["bundleId"] = appBundleId
            if let reason = reason {
                metadata["reason"] = reason
            }
            let event = SessionEvent(type: .unlockRequested, timestamp: Date(), metadata: metadata.isEmpty ? nil : metadata)
            addEventToSession(event)
            
            return createdRequest
        } catch {
            // If backend call fails, still keep the pending state
            // The shield extension will read it from AppGroupStorage
            throw error
        }
    }
    
    /// Approves an unlock request and writes the approved bundle ID to AppGroupStorage.
    /// - Parameter request: The unlock request to approve
    /// - Returns: The updated unlock request
    func approveUnlockRequest(_ request: UnlockRequest) async throws -> UnlockRequest {
        LoggerService.shared.logInfo("Approving unlock request: \(request.id.uuidString)", category: "Network")
        // Write setPendingUnlockRequest(false)
        appGroupStorage.setPendingUnlockRequest(false)
        
        // POST /unlock-requests/{id}/approve
        do {
            // Try to get response, but handle 204 No Content gracefully
            var approvedRequest: UnlockRequest?
            
            do {
                let responseDTO: UnlockRequestDTO = try await apiClient.request(.approveUnlockRequest(id: request.id), responseType: UnlockRequestDTO.self)
                approvedRequest = responseDTO.toUnlockRequest()
            } catch let error as AnchorAPIError {
                // If decoding error (likely 204 No Content), fall back to local state
                if case .decodingError(let underlyingError) = error,
                   let nsError = underlyingError as NSError?,
                   nsError.code == 204 || (nsError.userInfo[NSLocalizedDescriptionKey] as? String)?.contains("204") == true {
                    // Server returned 204 No Content - use local state
                    approvedRequest = nil
                } else {
                    throw error
                }
            }
            
            // Use response if available, otherwise create from local request
            let finalRequest: UnlockRequest
            if let approvedRequest = approvedRequest {
                finalRequest = approvedRequest
            } else {
                // Fallback to local state update when server returns 204
                finalRequest = UnlockRequest(
                    id: request.id,
                    sessionId: request.sessionId,
                    requesterId: request.requesterId,
                    partnerId: request.partnerId,
                    status: .approved,
                    message: request.message,
                    appBundleId: request.appBundleId,
                    createdAt: request.createdAt,
                    resolvedAt: Date()
                )
            }
            
            // Write approved bundle ID to AppGroupStorage for Shield to allow the app
            // Use unified method to set all flags atomically
            if let bundleId = finalRequest.appBundleId {
                appGroupStorage.setUnlockAllowed(bundleId: bundleId)
                LoggerService.shared.logInfo("Unlock approved for bundle: \(bundleId)", category: "Network")
            }
            appGroupStorage.setShieldState(
                ShieldState(
                    reason: .unlockApproved,
                    sessionId: finalRequest.sessionId
                )
            )
            
            // Add unlock approved event
            var metadata: [String: String] = [:]
            if let bundleId = finalRequest.appBundleId {
                metadata["bundleId"] = bundleId
            }
            let event = SessionEvent(type: .unlockApproved, timestamp: Date(), metadata: metadata.isEmpty ? nil : metadata)
            addEventToSession(event)
            
            // Note: We don't end the session or stop blocking here - that's handled by the legacy method
            // The shield extension will read the approved bundle ID and allow that specific app
            
            // Notify UI
            NotificationCenter.default.post(name: .unlockRequestStatusChanged, object: nil, userInfo: [
                "requestId": request.id.uuidString,
                "action": "approved"
            ])
            
            // Send notification to requester
            await notificationService.notifyUnlockRequestApproved(requestId: request.id.uuidString)
            
            return finalRequest
        } catch {
            // Continue with local operations even if backend call fails
            // Still write to AppGroupStorage for offline support using unified method
            if let bundleId = request.appBundleId {
                appGroupStorage.setUnlockAllowed(bundleId: bundleId)
            }
            appGroupStorage.setShieldState(
                ShieldState(
                    reason: .unlockApproved,
                    sessionId: request.sessionId
                )
            )
            
            // Add unlock approved event
            var metadata: [String: String] = [:]
            if let bundleId = request.appBundleId {
                metadata["bundleId"] = bundleId
            }
            let event = SessionEvent(type: .unlockApproved, timestamp: Date(), metadata: metadata.isEmpty ? nil : metadata)
            addEventToSession(event)
            
            // Return the request with updated status locally
            let approvedRequest = UnlockRequest(
                id: request.id,
                sessionId: request.sessionId,
                requesterId: request.requesterId,
                partnerId: request.partnerId,
                status: .approved,
                message: request.message,
                appBundleId: request.appBundleId,
                createdAt: request.createdAt,
                resolvedAt: Date()
            )
            
            NotificationCenter.default.post(name: .unlockRequestStatusChanged, object: nil, userInfo: [
                "requestId": request.id.uuidString,
                "action": "approved"
            ])
            
            await notificationService.notifyUnlockRequestApproved(requestId: request.id.uuidString)
            
            return approvedRequest
        }
    }
    
    /// Denies an unlock request.
    /// - Parameter request: The unlock request to deny
    /// - Returns: The updated unlock request
    func denyUnlockRequest(_ request: UnlockRequest) async throws -> UnlockRequest {
        LoggerService.shared.logInfo("Denying unlock request: \(request.id.uuidString)", category: "Network")
        // Write setPendingUnlockRequest(false)
        appGroupStorage.setPendingUnlockRequest(false)
        
        // POST /unlock-requests/{id}/reject
        do {
            // Try to get response, but handle 204 No Content gracefully
            var deniedRequest: UnlockRequest?
            
            do {
                let responseDTO: UnlockRequestDTO = try await apiClient.request(.rejectUnlockRequest(id: request.id), responseType: UnlockRequestDTO.self)
                deniedRequest = responseDTO.toUnlockRequest()
            } catch let error as AnchorAPIError {
                // If decoding error (likely 204 No Content), fall back to local state
                if case .decodingError(let underlyingError) = error,
                   let nsError = underlyingError as NSError?,
                   nsError.code == 204 || (nsError.userInfo[NSLocalizedDescriptionKey] as? String)?.contains("204") == true {
                    // Server returned 204 No Content - use local state
                    deniedRequest = nil
                } else {
                    throw error
                }
            }
            
            // Use response if available, otherwise create from local request
            let finalRequest: UnlockRequest
            if let deniedRequest = deniedRequest {
                finalRequest = deniedRequest
            } else {
                // Fallback to local state update when server returns 204
                finalRequest = UnlockRequest(
                    id: request.id,
                    sessionId: request.sessionId,
                    requesterId: request.requesterId,
                    partnerId: request.partnerId,
                    status: .denied,
                    message: request.message,
                    appBundleId: request.appBundleId,
                    createdAt: request.createdAt,
                    resolvedAt: Date()
                )
            }
            
            // Add unlock denied event
            var metadata: [String: String] = [:]
            if let bundleId = finalRequest.appBundleId {
                metadata["bundleId"] = bundleId
            }
            let event = SessionEvent(type: .unlockDenied, timestamp: Date(), metadata: metadata.isEmpty ? nil : metadata)
            addEventToSession(event)
            
            appGroupStorage.setShieldState(
                ShieldState(
                    reason: .activeLock,
                    sessionId: request.sessionId
                )
            )
            
            // Notify UI
            NotificationCenter.default.post(name: .unlockRequestStatusChanged, object: nil, userInfo: [
                "requestId": request.id.uuidString,
                "action": "denied"
            ])
            
            // Send notification to requester
            await notificationService.notifyUnlockRequestRejected(requestId: request.id.uuidString)
            
            return finalRequest
        } catch {
            // Continue with local operations even if backend call fails
            // Add unlock denied event
            var metadata: [String: String] = [:]
            if let bundleId = request.appBundleId {
                metadata["bundleId"] = bundleId
            }
            let event = SessionEvent(type: .unlockDenied, timestamp: Date(), metadata: metadata.isEmpty ? nil : metadata)
            addEventToSession(event)
            
            appGroupStorage.setShieldState(
                ShieldState(
                    reason: .activeLock,
                    sessionId: request.sessionId
                )
            )
            
            // Return the request with updated status locally
            let deniedRequest = UnlockRequest(
                id: request.id,
                sessionId: request.sessionId,
                requesterId: request.requesterId,
                partnerId: request.partnerId,
                status: .denied,
                message: request.message,
                appBundleId: request.appBundleId,
                createdAt: request.createdAt,
                resolvedAt: Date()
            )
            
            NotificationCenter.default.post(name: .unlockRequestStatusChanged, object: nil, userInfo: [
                "requestId": request.id.uuidString,
                "action": "denied"
            ])
            
            await notificationService.notifyUnlockRequestRejected(requestId: request.id.uuidString)
            
            return deniedRequest
        }
    }
    
    /// Fetches all pending unlock requests.
    /// - Returns: Array of pending unlock requests
    func fetchPendingRequests() async throws -> [UnlockRequest] {
        return try await getPendingUnlockRequests()
    }
    
    // MARK: - Legacy Methods (Backward Compatibility)
    
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
        
        // Create unlock request object (without appBundleId for legacy method)
        let unlockRequest = UnlockRequest(
            id: UUID(),
            sessionId: sessionIdUUID,
            requesterId: requesterId,
            partnerId: partnerId,
            status: .pending,
            message: reason,
            appBundleId: nil,
            createdAt: Date(),
            resolvedAt: nil
        )
        
        // POST /unlock-requests
        do {
            try await apiClient.request(.createUnlockRequest(request: unlockRequest))
        } catch let error as AnchorAPIError {
            // Check if it's a network error and we're offline
            if case .networkError = error, !networkMonitor.isConnected {
                // Queue the request for later retry
                let queuedRequest = UnlockRequest(
                    id: unlockRequest.id,
                    sessionId: unlockRequest.sessionId,
                    requesterId: unlockRequest.requesterId,
                    partnerId: unlockRequest.partnerId,
                    status: .queued,
                    message: unlockRequest.message,
                    appBundleId: unlockRequest.appBundleId,
                    createdAt: unlockRequest.createdAt,
                    resolvedAt: nil
                )
                
                do {
                    try persistenceService.saveQueuedUnlockRequest(queuedRequest)
                    print("📦 [UnlockRequestService] Queued unlock request for offline retry: \(unlockRequest.id.uuidString)")
                } catch {
                    print("❌ [UnlockRequestService] Failed to queue unlock request: \(error.localizedDescription)")
                }
            }
            // If backend call fails, still keep the pending state
            // The shield extension will read it from AppGroupStorage
            throw error
        } catch {
            // Handle non-AnchorAPIError errors
            if !networkMonitor.isConnected {
                // Queue the request for later retry
                let queuedRequest = UnlockRequest(
                    id: unlockRequest.id,
                    sessionId: unlockRequest.sessionId,
                    requesterId: unlockRequest.requesterId,
                    partnerId: unlockRequest.partnerId,
                    status: .queued,
                    message: unlockRequest.message,
                    appBundleId: unlockRequest.appBundleId,
                    createdAt: unlockRequest.createdAt,
                    resolvedAt: nil
                )
                
                do {
                    try persistenceService.saveQueuedUnlockRequest(queuedRequest)
                    print("📦 [UnlockRequestService] Queued unlock request for offline retry: \(unlockRequest.id.uuidString)")
                } catch {
                    print("❌ [UnlockRequestService] Failed to queue unlock request: \(error.localizedDescription)")
                }
            }
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
            _ = UnlockRequestError.backendFailure(underlying: error)
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
    
    // MARK: - Approve Unlock Request (Legacy)
    func approveUnlockRequest(requestId: String) async throws {
        // Fetch the request first to get appBundleId
        let requests = try await getPendingUnlockRequests()
        guard let request = requests.first(where: { $0.id.uuidString == requestId }) else {
            throw AnchorAPIError.notFound
        }
        
        // Use the new method to approve (this writes bundle ID to AppGroupStorage)
        _ = try await approveUnlockRequest(request)
        
        // Legacy behavior: end session and stop blocking
        // Note: This may not be desired for all unlock requests, but keeping for backward compatibility
        try await sessionService.endSession()
        await screenTimeService.stopBlocking()
        appGroupStorage.clearSessionState()
    }
    
    // MARK: - Deny Unlock Request (Legacy)
    func denyUnlockRequest(requestId: String) async throws {
        // Fetch the request first
        let requests = try await getPendingUnlockRequests()
        guard let request = requests.first(where: { $0.id.uuidString == requestId }) else {
            throw AnchorAPIError.notFound
        }
        
        // Use the new method to deny
        _ = try await denyUnlockRequest(request)
    }
}

