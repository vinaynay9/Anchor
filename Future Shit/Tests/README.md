# Anchor Testing Infrastructure

This directory contains the testing infrastructure for Anchor's core services, including mock implementations and unit tests.

## Overview

The testing infrastructure provides:
- **Mock Services**: Lightweight implementations of service protocols for isolated testing
- **Unit Tests**: Fast, focused tests verifying core service flows
- **Test Utilities**: Helper methods and test data factories

## Mock Services

Mock services are located in `Tests/Mocks/` and implement the same protocols as production services:

- `MockFriendService` - Implements `FriendServiceProtocol`
- `MockSessionService` - Implements `SessionServiceProtocol`
- `MockUnlockRequestService` - Implements `UnlockRequestServiceProtocol`
- `MockUserService` - Implements `UserServiceProtocol`

### How Mocks Work

Mock services provide:
1. **Predefined Data**: Set up test data before calling methods
2. **Error Injection**: Configure errors to test failure paths
3. **Call Tracking**: Verify methods were called with expected parameters
4. **State Management**: Maintain internal state for realistic behavior

### Example Usage

```swift
// Setup
let mockService = MockFriendService()
mockService.friends = [friend1, friend2]

// Test success path
let result = try await mockService.getFriends()
XCTAssertEqual(result.count, 2)

// Test error path
mockService.shouldThrowError = AnchorAPIError.unauthorized
do {
    _ = try await mockService.getFriends()
    XCTFail("Expected error")
} catch {
    // Verify error handling
}
```

### Mock Service Features

Each mock service includes:
- **State Variables**: Store test data (e.g., `friends`, `currentUser`)
- **Error Control**: `shouldThrowError` property for error injection
- **Call Tracking**: Boolean flags (e.g., `getFriendsCalled`) to verify method invocations
- **Reset Method**: `reset()` to clear state between tests

## Unit Tests

Unit tests are located in `Tests/` and follow the naming convention `*ServiceTests.swift`:

- `FriendServiceTests.swift` - Tests friend management operations
- `SessionServiceTests.swift` - Tests session lifecycle
- `UnlockRequestServiceTests.swift` - Tests unlock request flows
- `UserServiceTests.swift` - Tests user management operations

### Test Structure

Each test file follows this pattern:
1. **Setup**: Create mock service instance in `setUp()`
2. **Test Cases**: 2-3 tests per service method (success + error paths)
3. **Teardown**: Reset mock service in `tearDown()`

### Running Tests

Tests can be run via:
- **Xcode**: Cmd+U or Product > Test
- **Command Line**: `xcodebuild test -scheme AnchorApp -destination 'platform=iOS Simulator,name=iPhone 15'`
- **Swift Package Manager**: If using SPM, tests run automatically with `swift test`

### Test Performance

All tests are designed to run quickly (< 100ms per test):
- No network calls
- No file I/O
- Minimal async overhead
- Fast mock implementations

## Best Practices

1. **Isolation**: Each test is independent and doesn't rely on other tests
2. **Clear Naming**: Test names describe what they verify (e.g., `testGetFriends_Success`)
3. **Arrange-Act-Assert**: Follow AAA pattern for test structure
4. **Error Coverage**: Test both success and error paths
5. **Fast Execution**: Keep tests under 100ms each

## Adding New Tests

To add tests for a new service:

1. Create mock service in `Tests/Mocks/Mock[ServiceName]Service.swift`
2. Implement the service protocol
3. Add state variables and error injection
4. Create test file `Tests/[ServiceName]ServiceTests.swift`
5. Write 2-3 tests per method (success + error paths)

## Notes

- Mocks do NOT modify production code
- Tests are isolated from real services
- All async operations use Swift concurrency (`async/await`)
- Error types match production error types (`AnchorAPIError`)

