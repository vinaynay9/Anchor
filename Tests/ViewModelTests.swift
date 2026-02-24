import XCTest
@testable import AnchorApp
@testable import Shared

/// Unit tests for ViewModels using mock services
final class ViewModelTests: XCTestCase {
    
    // MARK: - SessionViewModel Tests
    
    @MainActor
    func testSessionViewModelStartSessionSuccess() async {
        // Given
        let mockService = MockSessionService()
        let mockScreenTime = MockScreenTimeService.shared
        mockScreenTime.simulatedAuthorizationStatus = .approved
        
        let viewModel = SessionViewModel(
            sessionService: mockService,
            screenTimeService: mockScreenTime
        )
        
        viewModel.selectedDurationMinutes = 30
        viewModel.selectedFriendIds = ["friend-123"]
        
        // When
        await viewModel.startSession()
        
        // Then
        XCTAssertTrue(mockService.startSessionCalled)
        XCTAssertNotNil(viewModel.activeSession)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testSessionViewModelStartSessionUnauthorized() async {
        // Given
        let mockService = MockSessionService()
        let mockScreenTime = MockScreenTimeService.shared
        mockScreenTime.reset()
        mockScreenTime.simulatedAuthorizationStatus = .denied
        mockScreenTime.simulateAuthorizationFailure = true
        
        let viewModel = SessionViewModel(
            sessionService: mockService,
            screenTimeService: mockScreenTime
        )
        
        // When
        await viewModel.startSession()
        
        // Then
        XCTAssertFalse(mockService.startSessionCalled)
        XCTAssertNil(viewModel.activeSession)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testSessionViewModelEndSession() async {
        // Given
        let mockService = MockSessionService()
        mockService.setMockActiveSession()
        
        let viewModel = SessionViewModel(sessionService: mockService)
        viewModel.loadActiveSession()
        
        // Wait for async load
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // When
        viewModel.endSession()
        
        // Wait for async end
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertTrue(mockService.endSessionCalled)
        XCTAssertNil(viewModel.activeSession)
    }
    
    @MainActor
    func testSessionViewModelLoadActiveSession() async {
        // Given
        let mockService = MockSessionService()
        mockService.setMockActiveSession(durationMinutes: 45)
        
        let viewModel = SessionViewModel(sessionService: mockService)
        
        // When
        viewModel.loadActiveSession()
        
        // Wait for async load
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Then
        XCTAssertTrue(mockService.getActiveSessionCalled)
        XCTAssertNotNil(viewModel.activeSession)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - FriendsViewModel Tests
    
    @MainActor
    func testFriendsViewModelLoadFriends() async {
        // Given
        let mockService = MockFriendService()
        let mockFriend = createMockFriend()
        mockService.friends = [mockFriend]
        
        let viewModel = FriendsViewModel(friendService: mockService)
        
        // When
        viewModel.loadFriends()
        
        // Wait for async load
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Then
        XCTAssertEqual(viewModel.friends.count, 1)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    @MainActor
    func testFriendsViewModelAddFriendValidation() async {
        // Given
        let mockService = MockFriendService()
        let viewModel = FriendsViewModel(friendService: mockService)
        
        // When - empty input
        viewModel.addFriend("")
        
        // Then
        XCTAssertNotNil(viewModel.addError)
        XCTAssertFalse(mockService.addFriendCalled)
    }
    
    @MainActor
    func testFriendsViewModelAcceptFriendRequest() async {
        // Given
        let mockService = MockFriendService()
        let mockRequest = createMockFriend()
        mockService.friendRequests = [mockRequest]
        
        let viewModel = FriendsViewModel(friendService: mockService)
        viewModel.loadFriendRequests()
        
        // Wait for load
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // When
        viewModel.acceptFriendRequest(mockRequest)
        
        // Wait for accept
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Then
        XCTAssertTrue(mockService.acceptFriendRequestCalled)
    }
    
    // MARK: - AuthViewModel Tests
    
    @MainActor
    func testAuthViewModelLoadCurrentUserNil() async {
        // Given
        let mockAuthService = MockAuthService()
        mockAuthService.currentUserResult = nil
        
        let viewModel = AuthViewModel(authService: mockAuthService)
        
        // Wait for initial load
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        // Then
        XCTAssertNil(viewModel.currentUser)
        XCTAssertFalse(viewModel.needsUsernameSetup)
    }
    
    // MARK: - Helper Methods
    
    private func createMockFriend() -> Friend {
        let user = User(
            id: UUID(),
            email: "test@test.com",
            username: "testuser",
            displayName: "Test User",
            createdAt: Date()
        )
        
        return Friend(
            id: UUID(),
            userId: UUID(),
            friendId: UUID(),
            friend: user,
            status: .accepted,
            createdAt: Date()
        )
    }
}

// MARK: - Mock Auth Service

final class MockAuthService: AuthServiceProtocol {
    var currentUserResult: User?
    var signInResult: User?
    var shouldThrowError: Error?
    
    func signUp(email: String, password: String) async throws -> User {
        if let error = shouldThrowError { throw error }
        guard let result = signInResult else {
            throw AuthError.notAuthenticated
        }
        return result
    }

    func signIn(email: String, password: String) async throws -> User {
        if let error = shouldThrowError { throw error }
        guard let result = signInResult else {
            throw AuthError.notAuthenticated
        }
        return result
    }
    
    func signOut() async throws {
        if let error = shouldThrowError { throw error }
        currentUserResult = nil
    }
    
    func currentUser() async throws -> User? {
        if let error = shouldThrowError { throw error }
        return currentUserResult
    }
}
