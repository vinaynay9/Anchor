import XCTest
@testable import AnchorApp
@testable import Shared

final class AdminAccessPolicyTests: XCTestCase {
    func testRoleBasedAdminAccessPolicy() {
        let policy = RoleBasedAdminAccessPolicy()
        let admin = User(
            id: UUID(),
            email: "admin@example.com",
            username: "admin",
            displayName: nil,
            createdAt: Date(),
            role: .admin
        )
        let user = User(
            id: UUID(),
            email: "user@example.com",
            username: "user",
            displayName: nil,
            createdAt: Date(),
            role: .user
        )
        
        XCTAssertTrue(policy.isAdmin(user: admin))
        XCTAssertFalse(policy.isAdmin(user: user))
        XCTAssertFalse(policy.isAdmin(user: nil))
    }
}
