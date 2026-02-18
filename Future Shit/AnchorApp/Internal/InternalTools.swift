import Foundation
import Shared

enum InternalToolsKeys {
    static let isEnabled = "internalToolsEnabled"
}

enum InternalTools {
    private static let accessPolicy: AdminAccessPolicy = RoleBasedAdminAccessPolicy()
    
    static var isCompiledIn: Bool {
        #if INTERNAL_TOOLS
        return true
        #elseif DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var isRuntimeEnabled: Bool {
        guard isCompiledIn else { return false }
        return UserDefaults.standard.bool(forKey: InternalToolsKeys.isEnabled)
    }
    
    static func setRuntimeEnabled(_ enabled: Bool) {
        guard isCompiledIn else { return }
        UserDefaults.standard.set(enabled, forKey: InternalToolsKeys.isEnabled)
    }
    
    static func canToggle(user: User?) -> Bool {
        isCompiledIn && accessPolicy.isAdmin(user: user)
    }
    
    static func canAccessAdmin(user: User?) -> Bool {
        isCompiledIn && isRuntimeEnabled && accessPolicy.isAdmin(user: user)
    }
}
