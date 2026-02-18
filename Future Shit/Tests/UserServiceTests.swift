import XCTest
import Foundation
@testable import AnchorApp
@testable import Shared

/// Unit tests for UserService using MockUserService.
/// Tests verify user management flows including retrieval, updates, and search.
final class UserServiceTests: XCTestCase {
    var mockService: MockUserService!
    
    override func setUp() {
        super.setUp()
        mockService = MockUserService()
    }
    
    override func tearDown() {
        mockService.reset()
        mockService = nil
        super.tearDown()
    }
    
    // MARK: - getCurrentUser Tests
    
    func testGetCurrentUser_Success() async throws {
        // Given: Mock service has current user configured
        let expectedUser = User(
            id: UUID(),
            email: "test@example.com",
            username: "testuser",
            displayName: "Test User",
            createdAt: Date()
        )
        mockService.currentUser = expectedUser
        
        // When: Getting current user
        let result = try await mockService.getCurrentUser()
        
        // Then: Should return configured user
        XCTAssertTrue(mockService.getCurrentUserCalled)
        XCTAssertEqual(result.id, expectedUser.id)
        XCTAssertEqual(result.email, expectedUser.email)
        XCTAssertEqual(result.username, expectedUser.username)
    }
    
    func testGetCurrentUser_NotFound() async {
        // Given: Mock service has no current user
        mockService.currentUser = nil
        
        // When/Then: Should throw not found error
        do {
            _ = try await mockService.getCurrentUser()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
            let nsError = error as NSError
            XCTAssertEqual(nsError.code, 404)
        }
    }
    
    func testGetCurrentUser_Error() async {
        // Given: Mock service configured to throw error
        let expectedError = AnchorAPIError.unauthorized
        mockService.shouldThrowError = expectedError
        
        // When/Then: Should throw configured error
        do {
            _ = try await mockService.getCurrentUser()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - getUser Tests
    
    func testGetUser_Success() async throws {
        // Given: Mock service has user with specific ID
        let userId = UUID()
        let expectedUser = User(
            id: userId,
            email: "user@example.com",
            username: "user",
            displayName: nil,
            createdAt: Date()
        )
        mockService.users[userId] = expectedUser
        
        // When: Getting user by ID
        let result = try await mockService.getUser(id: userId)
        
        // Then: Should return correct user
        XCTAssertTrue(mockService.getUserCalled)
        XCTAssertEqual(result.id, userId)
        XCTAssertEqual(result.email, expectedUser.email)
    }
    
    func testGetUser_NotFound() async {
        // Given: Mock service has no user for ID
        let userId = UUID()
        mockService.users = [:]
        
        // When/Then: Should throw not found error
        do {
            _ = try await mockService.getUser(id: userId)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
            let nsError = error as NSError
            XCTAssertEqual(nsError.code, 404)
        }
    }
    
    // MARK: - updateUser Tests
    
    func testUpdateUser_Success() async throws {
        // Given: Current user exists
        let originalUser = User(
            id: UUID(),
            email: "test@example.com",
            username: "oldusername",
            displayName: "Old Name",
            createdAt: Date()
        )
        mockService.currentUser = originalUser
        
        // When: Updating user with new values
        let newUsername = "newusername"
        let newDisplayName = "New Name"
        let result = try await mockService.updateUser(username: newUsername, displayName: newDisplayName)
        
        // Then: Should update and return modified user
        XCTAssertTrue(mockService.updateUserCalled)
        XCTAssertEqual(result.username, newUsername)
        XCTAssertEqual(result.displayName, newDisplayName)
        XCTAssertEqual(result.id, originalUser.id) // ID should remain same
    }
    
    func testUpdateUser_PartialUpdate() async throws {
        // Given: Current user exists
        let originalUser = User(
            id: UUID(),
            email: "test@example.com",
            username: "original",
            displayName: "Original",
            createdAt: Date()
        )
        mockService.currentUser = originalUser
        
        // When: Updating only username (displayName is nil)
        let result = try await mockService.updateUser(username: "updated", displayName: nil)
        
        // Then: Should update username, keep original displayName
        XCTAssertEqual(result.username, "updated")
        XCTAssertEqual(result.displayName, originalUser.displayName)
    }
    
    // MARK: - searchUsers Tests
    
    func testSearchUsers_Success() async throws {
        // Given: Mock service has search results configured
        let user1 = User(
            id: UUID(),
            email: "user1@example.com",
            username: "alice",
            displayName: "Alice",
            createdAt: Date()
        )
        let user2 = User(
            id: UUID(),
            email: "user2@example.com",
            username: "bob",
            displayName: "Bob",
            createdAt: Date()
        )
        mockService.searchResults = [user1, user2]
        
        // When: Searching users
        let result = try await mockService.searchUsers(query: "alice")
        
        // Then: Should return search results
        XCTAssertTrue(mockService.searchUsersCalled)
        XCTAssertEqual(result.count, 2)
    }
    
    func testSearchUsers_Error() async {
        // Given: Mock service configured to throw error
        let expectedError = AnchorAPIError.networkError(NSError(domain: "Test", code: -1))
        mockService.shouldThrowError = expectedError
        
        // When/Then: Should throw error
        do {
            _ = try await mockService.searchUsers(query: "test")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}

