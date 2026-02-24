import XCTest
@testable import Shared

/// Unit tests for AppGroupStorage
/// Tests write/read round trips and session state synchronization
final class AppGroupStorageTests: XCTestCase {
    
    var storage: AppGroupStorage!
    
    override func setUp() {
        super.setUp()
        storage = AppGroupStorage.shared
        // Clear any existing state before each test
        storage.clearSessionState()
        storage.setPendingUnlockRequest(false)
        storage.clearUnlockApproval()
        storage.clearCurrentSessionFriendIds()
        storage.clearPendingDeepLinkContext()
    }
    
    override func tearDown() {
        // Clean up after tests
        storage.clearSessionState()
        storage.setPendingUnlockRequest(false)
        storage.clearUnlockApproval()
        storage.clearCurrentSessionFriendIds()
        storage.clearPendingDeepLinkContext()
        super.tearDown()
    }
    
    // MARK: - Session State Tests
    
    func testSessionStateWriteReadRoundTrip() {
        // Given
        let state = SharedSessionState(
            isActive: true,
            endTime: Date().addingTimeInterval(3600),
            remainingSeconds: 3600
        )
        
        // When
        storage.setSessionState(state)
        let retrieved = storage.getSessionState()
        
        // Then
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.isActive, true)
        XCTAssertEqual(retrieved?.remainingSeconds, 3600)
    }
    
    func testSessionStateClear() {
        // Given
        let state = SharedSessionState(isActive: true, endTime: Date(), remainingSeconds: 100)
        storage.setSessionState(state)
        
        // When
        storage.clearSessionState()
        
        // Then
        XCTAssertNil(storage.getSessionState())
    }
    
    func testUpdateRemainingSeconds() {
        // Given
        let state = SharedSessionState(isActive: true, endTime: Date(), remainingSeconds: 1000)
        storage.setSessionState(state)
        
        // When
        storage.updateRemainingSeconds(500)
        
        // Then
        let updated = storage.getSessionState()
        XCTAssertEqual(updated?.remainingSeconds, 500)
        XCTAssertEqual(updated?.isActive, true)
    }
    
    // MARK: - Unlock Request Tests
    
    func testPendingUnlockRequestFlag() {
        // Initially false
        XCTAssertFalse(storage.hasPendingUnlockRequest())
        
        // Set to true
        storage.setPendingUnlockRequest(true)
        XCTAssertTrue(storage.hasPendingUnlockRequest())
        
        // Set back to false
        storage.setPendingUnlockRequest(false)
        XCTAssertFalse(storage.hasPendingUnlockRequest())
    }
    
    func testUnlockApprovalFlow() {
        // Given
        let bundleId = "com.test.app"
        
        // When
        storage.setUnlockAllowed(bundleId: bundleId)
        
        // Then
        XCTAssertTrue(storage.isUnlockApproved())
        XCTAssertEqual(storage.getUnlockAllowedBundleId(), bundleId)
        XCTAssertNotNil(storage.getUnlockApprovedTimestamp())
        
        // Clear
        storage.clearUnlockApproval()
        XCTAssertFalse(storage.isUnlockApproved())
        XCTAssertNil(storage.getUnlockAllowedBundleId())
    }
    
    // MARK: - Friend IDs Tests
    
    func testFriendIdsWriteReadRoundTrip() {
        // Given
        let friendIds = ["friend-1", "friend-2", "friend-3"]
        
        // When
        storage.saveCurrentSessionFriendIds(friendIds)
        let retrieved = storage.loadCurrentSessionFriendIds()
        
        // Then
        XCTAssertEqual(retrieved.count, 3)
        XCTAssertEqual(retrieved, friendIds)
    }
    
    func testFriendIdsClear() {
        // Given
        storage.saveCurrentSessionFriendIds(["friend-1"])
        
        // When
        storage.clearCurrentSessionFriendIds()
        
        // Then
        XCTAssertEqual(storage.loadCurrentSessionFriendIds(), [])
    }
    
    // MARK: - Deep Link Context Tests
    
    func testDeepLinkContextWriteReadRoundTrip() {
        // Given
        let context = DeepLinkContext(
            unlockRequestId: "request-123",
            bundleId: "com.test.app"
        )
        
        // When
        storage.saveDeepLinkContext(context)
        let retrieved = storage.loadDeepLinkContext()
        
        // Then
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.unlockRequestId, "request-123")
        XCTAssertEqual(retrieved?.bundleId, "com.test.app")
    }
    
    func testDeepLinkContextClear() {
        // Given
        let context = DeepLinkContext(unlockRequestId: "test", bundleId: nil)
        storage.saveDeepLinkContext(context)
        
        // When
        storage.clearPendingDeepLinkContext()
        
        // Then
        XCTAssertNil(storage.loadDeepLinkContext())
    }
    
    // MARK: - Session Events Tests
    
    func testSessionEventsWriteReadRoundTrip() {
        // Given
        let sessionId = UUID()
        let events = [
            SessionEvent(type: .sessionStarted, timestamp: Date()),
            SessionEvent(type: .proofSubmitted, timestamp: Date())
        ]
        
        // When
        storage.saveSessionEvents(events, forSessionId: sessionId)
        let retrieved = storage.loadSessionEvents(forSessionId: sessionId)
        
        // Then
        XCTAssertEqual(retrieved.count, 2)
        XCTAssertEqual(retrieved[0].type, .sessionStarted)
        XCTAssertEqual(retrieved[1].type, .proofSubmitted)
    }
    
    // MARK: - App Group Identifier Test
    
    func testAppGroupIdentifierConsistency() {
        // Verify the app group identifier is correctly set
        XCTAssertEqual(AppGroupStorage.appGroupIdentifier, "group.com.vinay.anchor")
    }
    
    // MARK: - Storage Key Tests
    
    func testFamilyActivitySelectionKeyGeneration() {
        let sessionId = UUID()
        let key = AppGroupStorageKey.familyActivitySelectionKey(for: sessionId)
        
        XCTAssertTrue(key.hasPrefix("familyActivitySelection_"))
        XCTAssertTrue(key.contains(sessionId.uuidString))
    }
    
    func testScheduledSessionConfigurationKeyGeneration() {
        let sessionId = UUID()
        let key = AppGroupStorageKey.scheduledSessionConfigurationKey(for: sessionId)
        
        XCTAssertTrue(key.hasPrefix("scheduledSessionConfig_"))
        XCTAssertTrue(key.contains(sessionId.uuidString))
    }
    
    // MARK: - Unlock Expiration Tests
    
    func testUnlockExpirationCheck() {
        // When no unlock is set, should be expired
        XCTAssertTrue(storage.isUnlockExpired())
        
        // Set a fresh unlock
        storage.setUnlockAllowed(bundleId: "com.test.app")
        XCTAssertFalse(storage.isUnlockExpired())
    }
}
