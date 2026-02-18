import Foundation
import Shared

/// Mock implementation of UserServiceProtocol for testing.
/// Allows injection of predefined user data and error conditions.
final class MockUserService: UserServiceProtocol {
    var currentUser: User?
    var users: [UUID: User] = [:]
    var searchResults: [User] = []
    var shouldThrowError: Error?
    var getCurrentUserCalled = false
    var getUserCalled = false
    var updateUserCalled = false
    var searchUsersCalled = false
    
    func getCurrentUser() async throws -> User {
        if let error = shouldThrowError {
            throw error
        }
        getCurrentUserCalled = true
        guard let user = currentUser else {
            throw NSError(domain: "MockUserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        return user
    }
    
    func getUser(id: UUID) async throws -> User {
        if let error = shouldThrowError {
            throw error
        }
        getUserCalled = true
        guard let user = users[id] else {
            throw NSError(domain: "MockUserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        return user
    }
    
    func updateUser(username: String?, displayName: String?) async throws -> User {
        if let error = shouldThrowError {
            throw error
        }
        updateUserCalled = true
        guard var user = currentUser else {
            throw NSError(domain: "MockUserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        
        // Create updated user
        let updatedUser = User(
            id: user.id,
            email: user.email,
            username: username ?? user.username,
            displayName: displayName ?? user.displayName,
            createdAt: user.createdAt,
            role: user.role
        )
        currentUser = updatedUser
        return updatedUser
    }
    
    func searchUsers(query: String) async throws -> [User] {
        if let error = shouldThrowError {
            throw error
        }
        searchUsersCalled = true
        return searchResults
    }
    
    func reset() {
        currentUser = nil
        users = [:]
        searchResults = []
        shouldThrowError = nil
        getCurrentUserCalled = false
        getUserCalled = false
        updateUserCalled = false
        searchUsersCalled = false
    }
}
