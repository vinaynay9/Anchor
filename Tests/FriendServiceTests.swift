import XCTest
import Foundation
@testable import AnchorApp
@testable import Shared

/// Unit tests for FriendService using MockFriendService.
/// Tests verify core friend management flows including success and error scenarios.
final class FriendServiceTests: XCTestCase {
    var mockService: MockFriendService!
    
    override func setUp() {
        super.setUp()
        mockService = MockFriendService()
    }
    
    override func tearDown() {
        mockService.reset()
        mockService = nil
        super.tearDown()
    }
    
    // MARK: - getFriends Tests
    
    func testGetFriends_Success() async throws {
        // Given: Mock service returns predefined friends
        let friend1 = Friend(
            id: UUID(),
            userId: UUID(),
            friendId: UUID(),
            friend: nil,
            status: .accepted,
            createdAt: Date()
        )
        let friend2 = Friend(
            id: UUID(),
            userId: UUID(),
            friendId: UUID(),
            friend: nil,
            status: .accepted,
            createdAt: Date()
        )
        mockService.friends = [friend1, friend2]
        
        // When: Getting friends
        let result = try await mockService.getFriends()
        
        // Then: Should return all friends
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains(friend1))
        XCTAssertTrue(result.contains(friend2))
    }
    
    func testGetFriends_Error() async {
        // Given: Mock service configured to throw error
        let expectedError = AnchorAPIError.networkError(NSError(domain: "Test", code: -1))
        mockService.shouldThrowError = expectedError
        
        // When/Then: Should throw error
        do {
            _ = try await mockService.getFriends()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - addFriend Tests
    
    func testAddFriend_Success() async throws {
        // Given: Valid friend ID
        let friendId = UUID().uuidString
        
        // When: Adding friend
        try await mockService.addFriend(friendId: friendId)
        
        // Then: Should mark method as called
        XCTAssertTrue(mockService.addFriendCalled)
    }
    
    func testAddFriend_Error() async {
        // Given: Mock service configured to throw error
        let expectedError = AnchorAPIError.unauthorized
        mockService.shouldThrowError = expectedError
        
        // When/Then: Should throw error
        do {
            try await mockService.addFriend(friendId: UUID().uuidString)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(mockService.addFriendCalled)
        }
    }
    
    // MARK: - deleteFriend Tests
    
    func testDeleteFriend_Success() async throws {
        // Given: Friend exists in mock service
        let friendId = UUID()
        let friend = Friend(
            id: friendId,
            userId: UUID(),
            friendId: UUID(),
            friend: nil,
            status: .accepted,
            createdAt: Date()
        )
        mockService.friends = [friend]
        
        // When: Deleting friend
        try await mockService.deleteFriend(id: friendId.uuidString)
        
        // Then: Should remove friend and mark method as called
        XCTAssertTrue(mockService.deleteFriendCalled)
        XCTAssertTrue(mockService.friends.isEmpty)
    }
    
    func testDeleteFriend_Error() async {
        // Given: Mock service configured to throw error
        let expectedError = AnchorAPIError.notFound
        mockService.shouldThrowError = expectedError
        
        // When/Then: Should throw error
        do {
            try await mockService.deleteFriend(id: UUID().uuidString)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Friend Requests Tests
    
    func testGetFriendRequests_Success() async throws {
        // Given: Mock service has pending requests
        let request = Friend(
            id: UUID(),
            userId: UUID(),
            friendId: UUID(),
            friend: nil,
            status: .pending,
            createdAt: Date()
        )
        mockService.friendRequests = [request]
        
        // When: Getting friend requests
        let result = try await mockService.getFriendRequests()
        
        // Then: Should return pending requests
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.status, .pending)
    }
    
    func testAcceptFriendRequest_Success() async throws {
        // Given: Pending friend request exists
        let requestId = UUID()
        let request = Friend(
            id: requestId,
            userId: UUID(),
            friendId: UUID(),
            friend: nil,
            status: .pending,
            createdAt: Date()
        )
        mockService.friendRequests = [request]
        
        // When: Accepting request
        try await mockService.acceptFriendRequest(id: requestId.uuidString)
        
        // Then: Should move request to friends and mark as called
        XCTAssertTrue(mockService.acceptFriendRequestCalled)
        XCTAssertTrue(mockService.friendRequests.isEmpty)
        XCTAssertEqual(mockService.friends.count, 1)
    }
    
    func testRejectFriendRequest_Success() async throws {
        // Given: Pending friend request exists
        let requestId = UUID()
        let request = Friend(
            id: requestId,
            userId: UUID(),
            friendId: UUID(),
            friend: nil,
            status: .pending,
            createdAt: Date()
        )
        mockService.friendRequests = [request]
        
        // When: Rejecting request
        try await mockService.rejectFriendRequest(id: requestId.uuidString)
        
        // Then: Should remove request and mark as called
        XCTAssertTrue(mockService.rejectFriendRequestCalled)
        XCTAssertTrue(mockService.friendRequests.isEmpty)
    }
}

