import Foundation
import Shared

enum InternalToolsKeys {
    static let isEnabled = "internalToolsEnabled"
}

enum InternalTools {
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
        false
    }
    
    static func canAccessAdmin(user: User?) -> Bool {
        false
    }
}
