import Foundation
import Shared

/// Mock implementation of FriendServiceProtocol for testing.
/// Allows injection of predefined responses and error conditions.
final class MockFriendService: FriendServiceProtocol {
    var friends: [Friend] = []
    var friendRequests: [Friend] = []
    var shouldThrowError: Error?
    var addFriendCalled = false
    var deleteFriendCalled = false
    var acceptFriendRequestCalled = false
    var rejectFriendRequestCalled = false
    
    func getFriends() async throws -> [Friend] {
        if let error = shouldThrowError {
            throw error
        }
        return friends
    }
    
    func addFriend(friendId: String) async throws {
        if let error = shouldThrowError {
            throw error
        }
        addFriendCalled = true
    }
    
    func deleteFriend(id: String) async throws {
        if let error = shouldThrowError {
            throw error
        }
        deleteFriendCalled = true
        friends.removeAll { $0.id.uuidString == id }
    }
    
    func getFriendRequests() async throws -> [Friend] {
        if let error = shouldThrowError {
            throw error
        }
        return friendRequests
    }
    
    func acceptFriendRequest(id: String) async throws {
        if let error = shouldThrowError {
            throw error
        }
        acceptFriendRequestCalled = true
        if let index = friendRequests.firstIndex(where: { $0.id.uuidString == id }) {
            var accepted = friendRequests[index]
            friendRequests.remove(at: index)
            // In real implementation, this would update status to .accepted
            friends.append(accepted)
        }
    }
    
    func rejectFriendRequest(id: String) async throws {
        if let error = shouldThrowError {
            throw error
        }
        rejectFriendRequestCalled = true
        friendRequests.removeAll { $0.id.uuidString == id }
    }
    
    func reset() {
        friends = []
        friendRequests = []
        shouldThrowError = nil
        addFriendCalled = false
        deleteFriendCalled = false
        acceptFriendRequestCalled = false
        rejectFriendRequestCalled = false
    }
}

