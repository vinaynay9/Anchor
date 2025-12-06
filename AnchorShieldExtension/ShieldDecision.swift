import Foundation
import ManagedSettingsUI
import Shared
import os.log

// Lightweight logging for ShieldExtension (using os_log directly)
private let shieldLog = OSLog(subsystem: "com.vinay.Anchor", category: "Shield")

// MARK: - Shield Decision Helper
/// Encapsulates the logic for determining whether a shield should allow or deny an app.
/// This keeps shield decision logic in a small, testable helper rather than scattering it.
struct ShieldDecision {
    private let appGroupStorage = AppGroupStorage.shared
    
    /// The bundle ID of the currently blocked app (extracted from context or storage)
    let blockedBundleId: String?
    
    /// Validity window for unlock approval in seconds (5 minutes)
    private static let unlockValidityWindow: TimeInterval = 5 * 60
    
    init(context: ShieldConfigurationContext) {
        // Try to extract bundle ID from context
        // Note: ShieldConfigurationContext doesn't directly expose bundle ID,
        // but we can try to get app info from the application token if available
        let extractedBundleId = Self.extractBundleId(from: context)
        
        if let bundleId = extractedBundleId {
            // Store the extracted bundle ID for unlock flow
            appGroupStorage.setCurrentBlockedBundleId(bundleId)
            self.blockedBundleId = bundleId
            os_log("Shield: extracted bundle ID: %{public}@", log: shieldLog, type: .info, bundleId)
        } else {
            // Fall back to previously stored bundle ID
            self.blockedBundleId = appGroupStorage.getCurrentBlockedBundleId()
            os_log("Shield: using stored bundle ID: %{public}@", log: shieldLog, type: .info, self.blockedBundleId ?? "nil")
        }
    }
    
    /// Attempts to extract bundle ID from ShieldConfigurationContext.
    /// This is challenging because the context doesn't directly expose bundle ID.
    /// We try various approaches based on available information.
    private static func extractBundleId(from context: ShieldConfigurationContext) -> String? {
        // Unfortunately, ShieldConfigurationContext in ManagedSettingsUI
        // doesn't expose the bundle ID directly.
        // The application token is opaque and cannot be converted to bundle ID.
        //
        // However, we can try to use the localizedDisplayName if available,
        // but this is not reliable for bundle ID matching.
        //
        // For now, we rely on:
        // 1. Bundle ID being stored when user initiates unlock request
        // 2. The main app passing bundle ID via deep link context
        //
        // Future enhancement: Use App Store Connect API or local app database
        // to map application tokens to bundle IDs if needed.
        
        return nil
    }
    
    /// Determines whether the shield should allow the app based on unlock approval status.
    /// Validates that:
    /// 1. Unlock has been approved
    /// 2. Bundle ID matches (if available)
    /// 3. Approval timestamp is within validity window (5 minutes)
    /// - Returns: `.allow` if all conditions are met, `.deny` otherwise
    func shouldAllow() -> ShieldAction {
        // Cleanup expired unlock flags first
        appGroupStorage.cleanupExpiredUnlockFlags()
        
        // Check if unlock has been approved
        guard appGroupStorage.isUnlockApproved() else {
            os_log("Shield decision: deny (no unlock approval)", log: shieldLog, type: .info)
            return .deny
        }
        
        // Validate timestamp is within validity window
        if let timestamp = appGroupStorage.getUnlockApprovedTimestamp() {
            let elapsed = Date().timeIntervalSince(timestamp)
            if elapsed > Self.unlockValidityWindow {
                os_log("Shield decision: deny (approval expired after %.0f seconds)", log: shieldLog, type: .info, elapsed)
                clearAllUnlockFlags()
                return .deny
            }
        } else {
            // No timestamp found - deny for safety
            os_log("Shield decision: deny (no approval timestamp)", log: shieldLog, type: .info)
            clearAllUnlockFlags()
            return .deny
        }
        
        // Validate bundle ID match for security (if we have both IDs)
        let allowedBundleId = appGroupStorage.getUnlockAllowedBundleId()
        
        if let allowedBundleId = allowedBundleId, let blockedBundleId = blockedBundleId {
            // Only allow if bundle IDs match exactly
            guard allowedBundleId == blockedBundleId else {
                // Bundle ID mismatch - do NOT clear the flags yet!
                // The user might be opening a different app than the one they requested unlock for.
                // Keep the approval valid for the correct app.
                os_log("Shield decision: deny (bundle ID mismatch - allowed: %{public}@, blocked: %{public}@)", 
                       log: shieldLog, type: .info, allowedBundleId, blockedBundleId)
                return .deny
            }
        }
        
        // All checks passed - allow and cleanup
        os_log("Shield decision: allow", log: shieldLog, type: .info)
        clearAllUnlockFlags()
        
        return .allow
    }
    
    /// Clears all unlock-related flags.
    private func clearAllUnlockFlags() {
        appGroupStorage.clearUnlockApproved()
        appGroupStorage.clearUnlockAllowedBundleId()
        appGroupStorage.clearCurrentBlockedBundleId()
    }
    
    /// Checks if there's a pending unlock request for the current bundle ID.
    /// This can be used to show different UI states in the shield.
    /// - Returns: true if there's a pending unlock request
    func hasPendingUnlockRequest() -> Bool {
        return appGroupStorage.hasPendingUnlockRequest()
    }
    
    /// Checks if unlock has been approved (without clearing the flag).
    /// Used for UI state updates.
    /// - Returns: true if unlock has been approved and not expired
    func isUnlockApproved() -> Bool {
        // First check if approval flag is set
        guard appGroupStorage.isUnlockApproved() else {
            return false
        }
        
        // Then check if not expired
        if let timestamp = appGroupStorage.getUnlockApprovedTimestamp() {
            let elapsed = Date().timeIntervalSince(timestamp)
            return elapsed <= Self.unlockValidityWindow
        }
        
        return false
    }
}
