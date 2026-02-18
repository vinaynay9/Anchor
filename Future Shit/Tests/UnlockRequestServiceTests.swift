import XCTest
import Foundation
@testable import AnchorApp
@testable import Shared

/// Unit tests for UnlockRequestService using MockUnlockRequestService.
/// Tests verify unlock request flows including send, cancel, approve, and deny operations.
final class UnlockRequestServiceTests: XCTestCase {
    var mockService: MockUnlockRequestService!
    
    override func setUp() {
        super.setUp()
        mockService = MockUnlockRequestService()
    }
    
    override func tearDown() {
        mockService.reset()
        mockService = nil
        super.tearDown()
    }
    
    // MARK: - sendUnlockRequest Tests
    
    func testSendUnlockRequest_Success() async throws {
        // Given: Valid session ID and reason
        let sessionId = UUID().uuidString
        let reason = "Need to check urgent message"
        
        // When: Sending unlock request
        try await mockService.sendUnlockRequest(sessionId: sessionId, reason: reason)
        
        // Then: Should create request and mark as called
        XCTAssertTrue(mockService.sendUnlockRequestCalled)
        XCTAssertEqual(mockService.pendingRequests.count, 1)
        XCTAssertEqual(mockService.pendingRequests.first?.message, reason)
        XCTAssertEqual(mockService.pendingRequests.first?.status, .pending)
    }
    
    func testSendUnlockRequest_Error() async {
        // Given: Mock service configured to throw error
        let expectedError = AnchorAPIError.unauthorized
        mockService.shouldThrowError = expectedError
        
        // When/Then: Should throw error
        do {
            try await mockService.sendUnlockRequest(sessionId: UUID().uuidString, reason: "test")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - cancelUnlockRequest Tests
    
    func testCancelUnlockRequest_Success() async throws {
        // Given: Pending unlock request exists
        let sessionId = UUID().uuidString
        _ = try await mockService.sendUnlockRequest(sessionId: sessionId, reason: "test")
        XCTAssertEqual(mockService.pendingRequests.count, 1)
        
        // When: Cancelling request
        try await mockService.cancelUnlockRequest(sessionId: sessionId)
        
        // Then: Should remove request and mark as called
        XCTAssertTrue(mockService.cancelUnlockRequestCalled)
        XCTAssertTrue(mockService.pendingRequests.isEmpty)
    }
    
    func testCancelUnlockRequest_Error() async {
        // Given: Mock service configured to throw error
        let expectedError = AnchorAPIError.notFound
        mockService.shouldThrowError = expectedError
        
        // When/Then: Should throw error
        do {
            try await mockService.cancelUnlockRequest(sessionId: UUID().uuidString)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - getPendingUnlockRequests Tests
    
    func testGetPendingUnlockRequests_Success() async throws {
        // Given: Multiple pending requests exist
        _ = try await mockService.sendUnlockRequest(sessionId: UUID().uuidString, reason: "Reason 1")
        _ = try await mockService.sendUnlockRequest(sessionId: UUID().uuidString, reason: "Reason 2")
        
        // When: Getting pending requests
        let result = try await mockService.getPendingUnlockRequests()
        
        // Then: Should return all pending requests
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.status == .pending })
    }
    
    func testGetPendingUnlockRequests_Empty() async throws {
        // Given: No pending requests
        mockService.pendingRequests = []
        
        // When: Getting pending requests
        let result = try await mockService.getPendingUnlockRequests()
        
        // Then: Should return empty array
        XCTAssertTrue(result.isEmpty)
    }
    
    func testGetPendingUnlockRequests_Error() async {
        // Given: Mock service configured to throw error
        let expectedError = AnchorAPIError.networkError(NSError(domain: "Test", code: -1))
        mockService.shouldThrowError = expectedError
        
        // When/Then: Should throw error
        do {
            _ = try await mockService.getPendingUnlockRequests()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - approveUnlockRequest Tests
    
    func testApproveUnlockRequest_Success() async throws {
        // Given: Pending unlock request exists
        let sessionId = UUID().uuidString
        _ = try await mockService.sendUnlockRequest(sessionId: sessionId, reason: "test")
        let requestId = mockService.pendingRequests.first!.id.uuidString
        
        // When: Approving request
        try await mockService.approveUnlockRequest(requestId: requestId)
        
        // Then: Should remove request and mark as called
        XCTAssertTrue(mockService.approveUnlockRequestCalled)
        XCTAssertTrue(mockService.pendingRequests.isEmpty)
    }
    
    func testApproveUnlockRequest_Error() async {
        // Given: Mock service configured to throw error
        let expectedError = AnchorAPIError.serverError(code: 500)
        mockService.shouldThrowError = expectedError
        
        // When/Then: Should throw error
        do {
            try await mockService.approveUnlockRequest(requestId: UUID().uuidString)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - denyUnlockRequest Tests
    
    func testDenyUnlockRequest_Success() async throws {
        // Given: Pending unlock request exists
        let sessionId = UUID().uuidString
        _ = try await mockService.sendUnlockRequest(sessionId: sessionId, reason: "test")
        let requestId = mockService.pendingRequests.first!.id.uuidString
        
        // When: Denying request
        try await mockService.denyUnlockRequest(requestId: requestId)
        
        // Then: Should remove request and mark as called
        XCTAssertTrue(mockService.denyUnlockRequestCalled)
        XCTAssertTrue(mockService.pendingRequests.isEmpty)
    }
    
    func testDenyUnlockRequest_Error() async {
        // Given: Mock service configured to throw error
        let expectedError = AnchorAPIError.unauthorized
        mockService.shouldThrowError = expectedError
        
        // When/Then: Should throw error
        do {
            try await mockService.denyUnlockRequest(requestId: UUID().uuidString)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}

