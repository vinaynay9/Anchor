import XCTest
import Foundation
@testable import AnchorApp
@testable import Shared

/// Unit tests for SessionService using MockSessionService.
/// Tests verify session lifecycle including start, end, and active session retrieval.
final class SessionServiceTests: XCTestCase {
    var mockService: MockSessionService!
    
    override func setUp() {
        super.setUp()
        mockService = MockSessionService()
    }
    
    override func tearDown() {
        mockService.reset()
        mockService = nil
        super.tearDown()
    }
    
    // MARK: - startSession Tests
    
    func testStartSession_Success() async throws {
        // Given: No active session and valid parameters
        let durationMinutes = 30
        let friendIds = [UUID().uuidString, UUID().uuidString]
        
        // When: Starting session
        let session = try await mockService.startSession(durationMinutes: durationMinutes, friendIds: friendIds)
        
        // Then: Should create and return active session
        XCTAssertTrue(mockService.startSessionCalled)
        XCTAssertEqual(session.status, .active)
        XCTAssertNotNil(session.endTime)
        XCTAssertNotNil(mockService.activeSession)
        XCTAssertEqual(mockService.activeSession?.id, session.id)
        
        // Verify end time is correct duration from start
        if let endTime = session.endTime {
            let duration = endTime.timeIntervalSince(session.startTime)
            XCTAssertEqual(duration, Double(durationMinutes * 60), accuracy: 1.0)
        }
    }
    
    func testStartSession_WithAccountabilityPartner() async throws {
        // Given: Friend IDs provided
        let friendId = UUID().uuidString
        let friendIds = [friendId]
        
        // When: Starting session
        let session = try await mockService.startSession(durationMinutes: 60, friendIds: friendIds)
        
        // Then: Should set accountability partner ID
        XCTAssertNotNil(session.accountabilityPartnerId)
        XCTAssertEqual(session.accountabilityPartnerId?.uuidString, friendId)
    }
    
    func testStartSession_Error() async {
        // Given: Mock service configured to throw error
        let expectedError = AnchorAPIError.serverError(code: 500)
        mockService.shouldThrowError = expectedError
        
        // When/Then: Should throw error
        do {
            _ = try await mockService.startSession(durationMinutes: 30, friendIds: [])
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - endSession Tests
    
    func testEndSession_Success() async throws {
        // Given: Active session exists
        let session = try await mockService.startSession(durationMinutes: 30, friendIds: [])
        XCTAssertNotNil(mockService.activeSession)
        
        // When: Ending session
        try await mockService.endSession()
        
        // Then: Should clear active session
        XCTAssertTrue(mockService.endSessionCalled)
        XCTAssertNil(mockService.activeSession)
    }
    
    func testEndSession_NoActiveSession() async throws {
        // Given: No active session
        mockService.activeSession = nil
        
        // When: Ending session (should not throw)
        try await mockService.endSession()
        
        // Then: Should mark as called but not error
        XCTAssertTrue(mockService.endSessionCalled)
    }
    
    func testEndSession_Error() async {
        // Given: Active session exists and service configured to throw error
        _ = try? await mockService.startSession(durationMinutes: 30, friendIds: [])
        let expectedError = AnchorAPIError.networkError(NSError(domain: "Test", code: -1))
        mockService.shouldThrowError = expectedError
        
        // When/Then: Should throw error
        do {
            try await mockService.endSession()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - getActiveSession Tests
    
    func testGetActiveSession_Success() async throws {
        // Given: Active session exists
        let createdSession = try await mockService.startSession(durationMinutes: 60, friendIds: [])
        
        // When: Getting active session
        let result = try await mockService.getActiveSession()
        
        // Then: Should return active session
        XCTAssertTrue(mockService.getActiveSessionCalled)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, createdSession.id)
        XCTAssertEqual(result?.status, .active)
    }
    
    func testGetActiveSession_NoActiveSession() async throws {
        // Given: No active session
        mockService.activeSession = nil
        
        // When: Getting active session
        let result = try await mockService.getActiveSession()
        
        // Then: Should return nil
        XCTAssertTrue(mockService.getActiveSessionCalled)
        XCTAssertNil(result)
    }
    
    func testGetActiveSession_Error() async {
        // Given: Mock service configured to throw error
        let expectedError = AnchorAPIError.unauthorized
        mockService.shouldThrowError = expectedError
        
        // When/Then: Should throw error
        do {
            _ = try await mockService.getActiveSession()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}

