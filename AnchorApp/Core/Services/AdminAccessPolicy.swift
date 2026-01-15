import Foundation
import Shared

protocol AdminAccessPolicy {
    func isAdmin(user: User?) -> Bool
}

struct RoleBasedAdminAccessPolicy: AdminAccessPolicy {
    func isAdmin(user: User?) -> Bool {
        user?.role == .admin
    }
}
