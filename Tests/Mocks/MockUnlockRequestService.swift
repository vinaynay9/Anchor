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
    
    func reset() {
        pendingRequests = []
        shouldThrowError = nil
        sendUnlockRequestCalled = false
        cancelUnlockRequestCalled = false
        approveUnlockRequestCalled = false
        denyUnlockRequestCalled = false
    }
}

