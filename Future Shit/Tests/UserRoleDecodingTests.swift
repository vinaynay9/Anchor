import XCTest
@testable import Shared

final class UserRoleDecodingTests: XCTestCase {
    func testUserDecodingDefaultsToUserRole() throws {
        let userId = UUID().uuidString
        let json = """
        {
          "id": "\(userId)",
          "email": "test@example.com",
          "username": "tester",
          "display_name": "Test User",
          "created_at": "2024-01-01T00:00:00Z"
        }
        """
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let user = try decoder.decode(User.self, from: Data(json.utf8))
        
        XCTAssertEqual(user.role, .user)
    }
    
    func testUserDecodingAdminRole() throws {
        let userId = UUID().uuidString
        let json = """
        {
          "id": "\(userId)",
          "email": "admin@example.com",
          "username": "admin",
          "display_name": "Admin User",
          "created_at": "2024-01-01T00:00:00Z",
          "role": "admin"
        }
        """
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let user = try decoder.decode(User.self, from: Data(json.utf8))
        
        XCTAssertEqual(user.role, .admin)
    }
}
