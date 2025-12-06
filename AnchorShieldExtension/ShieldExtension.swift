import ManagedSettingsUI
import SwiftUI
import Shared
import os.log

// MARK: - Shield Configuration Extension
// This is the main entry point for the Screen Time shield extension

private let shieldLog = OSLog(subsystem: "com.vinay.Anchor", category: "ShieldExtension")

@main
struct ShieldExtension: ShieldConfigurationDelegate {
    func shieldConfiguration(
        _ configuration: ShieldConfiguration,
        completionHandler: @escaping (ShieldAction) -> Void
    ) {
        os_log("Shield configuration called", log: shieldLog, type: .info)
        
        // Use ShieldDecision helper to:
        // 1. Extract and store bundle ID from context (if possible)
        // 2. Check if unlock has been approved for this specific app
        let decision = ShieldDecision(context: configuration.context)
        
        // Log decision context
        os_log("Shield decision context - bundleId: %{public}@, hasPending: %d, isApproved: %d",
               log: shieldLog, type: .info,
               decision.blockedBundleId ?? "nil",
               decision.hasPendingUnlockRequest(),
               decision.isUnlockApproved())
        
        // Determine action based on unlock approval status
        // - If unlock is approved and bundle ID matches: allow (shield won't be shown)
        // - Otherwise: deny (shield will be shown)
        let action = decision.shouldAllow()
        
        os_log("Shield action: %{public}@", log: shieldLog, type: .info, action == .allow ? "allow" : "deny")
        
        completionHandler(action)
    }
}

// MARK: - Shield Configuration View Provider
// This provides the actual view shown on the shield screen

struct ShieldConfigurationView: View {
    let context: ShieldConfigurationContext
    
    var body: some View {
        ShieldView(context: context)
    }
}

