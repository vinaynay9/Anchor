import Foundation
import Shared

/// Mock implementation of UnlockRequestServiceProtocol for testing.
/// Allows injection of predefined unlock requests and error conditions.
final class MockUnlockRequestService: UnlockRequestServiceProtocol {
    var pendingRequests: [UnlockRequest] = []
    var shouldThrowError: Error?
    var sendUnlockRequestCalled = false
    var cancelUnlockRequestCalled = false
    var approveUnlockRequestCalled = false
    var denyUnlockRequestCalled = false
    
    func sendUnlockRequest(sessionId: String, reason: String) async throws {
        if let error = shouldThrowError {
            throw error
        }
        sendUnlockRequestCalled = true
        
        let request = UnlockRequest(
            id: UUID(),
            sessionId: UUID(uuidString: sessionId) ?? UUID(),
            requesterId: UUID(),
            partnerId: UUID(),
            status: .pending,
            message: reason,
            appBundleId: nil,
            createdAt: Date(),
            resolvedAt: nil
        )
        pendingRequests.append(request)
    }
    
    func cancelUnlockRequest(sessionId: String) async throws {
        if let error = shouldThrowError {
            throw error
        }
        cancelUnlockRequestCalled = true
        pendingRequests.removeAll { $0.sessionId.uuidString == sessionId }
    }
    
    func getPendingUnlockRequests() async throws -> [UnlockRequest] {
        if let error = shouldThrowError {
            throw error
        }
        return pendingRequests
    }
    
    func approveUnlockRequest(requestId: String) async throws {
        if let error = shouldThrowError {
            throw error
        }
        approveUnlockRequestCalled = true
        if let index = pendingRequests.firstIndex(where: { $0.id.uuidString == requestId }) {
            pendingRequests.remove(at: index)
        }
    }
    
    func denyUnlockRequest(requestId: String) async throws {
        if let error = shouldThrowError {
            throw error
        }
        denyUnlockRequestCalled = true
        pendingRequests.removeAll { $0.id.uuidString == requestId }
    }
    
    // MARK: - New Methods (Matching Requirements)
    
    func submitUnlockRequest(session: LockSession, appBundleId: String, reason: String?) async throws -> UnlockRequest {
        if let error = shouldThrowError {
            throw error
        }
        sendUnlockRequestCalled = true
        
        let request = UnlockRequest(
            id: UUID(),
            sessionId: session.id,
            requesterId: UUID(),
            partnerId: session.accountabilityPartnerId ?? UUID(),
            status: .pending,
            message: reason,
            appBundleId: appBundleId,
            createdAt: Date(),
            resolvedAt: nil
        )
        pendingRequests.append(request)
        return request
    }
    
    func approveUnlockRequest(_ request: UnlockRequest) async throws -> UnlockRequest {
        if let error = shouldThrowError {
            throw error
        }
        approveUnlockRequestCalled = true
        if let index = pendingRequests.firstIndex(where: { $0.id == request.id }) {
            pendingRequests.remove(at: index)
        }
        return UnlockRequest(
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
    
    func denyUnlockRequest(_ request: UnlockRequest) async throws -> UnlockRequest {
        if let error = shouldThrowError {
            throw error
        }
        denyUnlockRequestCalled = true
        pendingRequests.removeAll { $0.id == request.id }
        return UnlockRequest(
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
    
    func fetchPendingRequests() async throws -> [UnlockRequest] {
        return try await getPendingUnlockRequests()
    }
    
    func reset() {
        pendingRequests = []
        shouldThrowError = nil
        sendUnlockRequestCalled = false
        cancelUnlockRequestCalled = false
        approveUnlockRequestCalled = false
        denyUnlockRequestCalled = false
    }
}

