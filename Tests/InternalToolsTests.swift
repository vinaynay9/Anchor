import XCTest
@testable import AnchorApp
@testable import Shared

final class InternalToolsTests: XCTestCase {
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: InternalToolsKeys.isEnabled)
        super.tearDown()
    }
    
    func testInternalToolsGateRequiresAdminRole() {
        let user = User(
            id: UUID(),
            email: "user@example.com",
            username: "user",
            displayName: nil,
            createdAt: Date(),
            role: .user
        )
        InternalTools.setRuntimeEnabled(true)
        
        XCTAssertFalse(InternalTools.canAccessAdmin(user: user))
        XCTAssertFalse(InternalTools.canToggle(user: user))
    }
    
    func testInternalToolsGateRequiresRuntimeToggle() {
        let admin = User(
            id: UUID(),
            email: "admin@example.com",
            username: "admin",
            displayName: nil,
            createdAt: Date(),
            role: .admin
        )
        
        InternalTools.setRuntimeEnabled(false)
        XCTAssertFalse(InternalTools.canAccessAdmin(user: admin))
        
        InternalTools.setRuntimeEnabled(true)
        if InternalTools.isCompiledIn {
            XCTAssertTrue(InternalTools.canAccessAdmin(user: admin))
        } else {
            XCTAssertFalse(InternalTools.canAccessAdmin(user: admin))
        }
    }
}
