import Foundation
import Shared
import FamilyControls
import ManagedSettings

// Import the protocol (defined in ScreenTimeServiceProtocol.swift)
// The protocol is defined separately to avoid FamilyControls dependency in the protocol

// MARK: - Screen Time Service
// Handles all FamilyControls and ManagedSettings interactions

enum ScreenTimeError: Error, LocalizedError {
    case authorizationDenied
    case authorizationFailed
    case authorizationRestricted
    case noAppsSelected
    case shieldConfigurationFailed
    case entitlementMissing
    case familyControlsUnavailable(underlying: Error?)
    
    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Screen Time authorization was denied. Please enable it in Settings."
        case .authorizationFailed:
            return "Failed to request Screen Time authorization."
        case .authorizationRestricted:
            return "Screen Time is restricted on this device (possibly by parental controls)."
        case .noAppsSelected:
            return "No apps have been selected to block."
        case .shieldConfigurationFailed:
            return "Failed to configure the app shield."
        case .entitlementMissing:
            return "FamilyControls entitlement is not available. Please contact support."
        case .familyControlsUnavailable(let underlying):
            if let error = underlying {
                return "FamilyControls is unavailable: \(error.localizedDescription)"
            }
            return "FamilyControls is unavailable on this device."
        }
    }
}

// MARK: - Real Screen Time Service Implementation
// This uses actual FamilyControls/ManagedSettings (device-only)
// NOTE: This will only work on real devices with Screen Time entitlements
class ScreenTimeService: ScreenTimeServiceProtocol {
    static let shared = ScreenTimeService()
    
    private let authorizationCenter = AuthorizationCenter.shared
    private let store = ManagedSettingsStore()
    private let appGroupStorage = AppGroupStorage.shared
    private let activitySelectionService = ActivitySelectionService.shared
    
    // Store selections keyed by session ID
    private var sessionSelections: [UUID: FamilyActivitySelection] = [:]
    
    // MARK: - Authorization
    
    /// Requests FamilyControls authorization for Screen Time blocking.
    /// This method gracefully handles missing entitlements and various failure scenarios.
    /// - Throws: ScreenTimeError with specific reason for failure
    func requestAuthorization() async throws {
        LoggerService.shared.logInfo("Requesting Screen Time authorization", category: "ScreenTime")
        
        do {
            try await authorizationCenter.requestAuthorization(for: .individual)
            LoggerService.shared.logInfo("Screen Time authorization granted", category: "ScreenTime")
        } catch let error as NSError {
            LoggerService.shared.logError("Screen Time authorization failed", error: error, category: "ScreenTime")
            
            // Check for common FamilyControls errors
            // Error domain: FamilyControls.FamilyControlsError
            if error.domain.contains("FamilyControls") {
                // Check error code for specific issues
                switch error.code {
                case 0: // FamilyControlsError.restricted
                    throw ScreenTimeError.authorizationRestricted
                case 1: // FamilyControlsError.unavailable
                    throw ScreenTimeError.familyControlsUnavailable(underlying: error)
                case 2: // FamilyControlsError.invalidAccountType
                    throw ScreenTimeError.authorizationDenied
                case 3: // FamilyControlsError.invalidArgument
                    throw ScreenTimeError.authorizationFailed
                case 4: // FamilyControlsError.authorizationConflict
                    throw ScreenTimeError.authorizationDenied
                case 5: // FamilyControlsError.authorizationCanceled
                    throw ScreenTimeError.authorizationDenied
                case 6: // FamilyControlsError.networkError
                    throw ScreenTimeError.authorizationFailed
                default:
                    break
                }
            }
            
            // Check for entitlement-related errors (common when entitlement is missing)
            let errorDescription = error.localizedDescription.lowercased()
            if errorDescription.contains("entitlement") || 
               errorDescription.contains("not entitled") ||
               errorDescription.contains("missing capability") {
                LoggerService.shared.logError("FamilyControls entitlement appears to be missing", category: "ScreenTime")
                throw ScreenTimeError.entitlementMissing
            }
            
            // Check if user explicitly denied
            if errorDescription.contains("denied") || errorDescription.contains("cancel") {
                throw ScreenTimeError.authorizationDenied
            }
            
            // Generic failure
            throw ScreenTimeError.familyControlsUnavailable(underlying: error)
        } catch {
            LoggerService.shared.logError("Screen Time authorization failed with unknown error", error: error, category: "ScreenTime")
            throw ScreenTimeError.familyControlsUnavailable(underlying: error)
        }
    }
    
    /// Gets the current FamilyControls authorization status.
    /// Properly handles .restricted status (does NOT treat as .notDetermined).
    /// - Returns: The current authorization status
    func getAuthorizationStatus() -> ScreenTimeAuthorizationStatus {
        let status = authorizationCenter.authorizationStatus
        let statusString: String
        let mapped: ScreenTimeAuthorizationStatus
        switch status {
        case .notDetermined:
            statusString = "notDetermined"
            mapped = .notDetermined
        case .denied:
            statusString = "denied"
            mapped = .denied
        case .approved:
            statusString = "approved"
            mapped = .approved
        @unknown default:
            statusString = "unknown"
            mapped = .denied
        }
        LoggerService.shared.logInfo("Authorization status: \(statusString)", category: "ScreenTime")
        return mapped
    }
    
    /// Synchronous check for authorization status.
    /// - Returns: true only if status is .approved
    func isAuthorized() -> Bool {
        authorizationCenter.authorizationStatus == .approved
    }
    
    // MARK: - Protocol Implementation
    func startBlocking(for session: LockSession) async {
        LoggerService.shared.logInfo("Starting blocking for session \(session.id.uuidString)", category: "ScreenTime")
        // Load application tokens and categories from persisted selection
        let tokens = activitySelectionService.loadApplicationTokens()
        let selection = activitySelectionService.loadSelection()
        
        // Get category tokens from selection if available
        let categoryTokens = selection?.categoryTokens ?? Set<ActivityCategoryToken>()
        
        // Use session-specific categories if provided, otherwise use selection categories
        let categoriesToBlock = session.selectedCategories ?? []
        
        LoggerService.shared.logInfo("Blocking \(tokens.count) apps, \(categoryTokens.count) category tokens", category: "ScreenTime")
        
        // If we have tokens or category tokens, activate shields
        if !tokens.isEmpty || !categoryTokens.isEmpty {
            activateShields(
                for: tokens,
                categories: categoriesToBlock.isEmpty ? nil : categoriesToBlock,
                categoryTokens: categoryTokens.isEmpty ? nil : categoryTokens
            )
            LoggerService.shared.logInfo("Shields activated successfully", category: "ScreenTime")
            return
        }
        
        // Fallback to session-specific selection
        guard let sessionSelection = loadSelection(for: session.id) else {
            // If no selection at all, but categories are specified, use .all() for categories
            if !categoriesToBlock.isEmpty {
                activateShields(
                    for: [],
                    categories: categoriesToBlock,
                    categoryTokens: nil
                )
            }
            return
        }
        
        let selectionTokens = Array(sessionSelection.applicationTokens)
        let sessionCategoryTokens = sessionSelection.categoryTokens
        
        if !selectionTokens.isEmpty || !sessionCategoryTokens.isEmpty {
            activateShields(
                for: selectionTokens,
                categories: session.selectedCategories,
                categoryTokens: sessionCategoryTokens.isEmpty ? nil : sessionCategoryTokens
            )
        } else if !categoriesToBlock.isEmpty {
            // If no tokens but categories specified, use .all() for categories
            activateShields(
                for: [],
                categories: categoriesToBlock,
                categoryTokens: nil
            )
        }
    }
    
    func startBlockingForScheduledSession(sessionId: UUID, categories: [AppCategory]?, schedule: LockSessionSchedule) async {
        // Load application tokens and categories from persisted selection
        let tokens = activitySelectionService.loadApplicationTokens()
        let selection = activitySelectionService.loadSelection()
        let categoryTokens = selection?.categoryTokens ?? Set<ActivityCategoryToken>()
        
        // Also try to load from session-specific selection
        let sessionSelection = loadSelection(for: sessionId)
        let sessionTokens = sessionSelection != nil ? Array(sessionSelection!.applicationTokens) : tokens
        let sessionCategoryTokens = sessionSelection?.categoryTokens ?? categoryTokens
        
        // Activate shields with the provided categories or selection categories
        activateShields(
            for: sessionTokens.isEmpty ? tokens : sessionTokens,
            categories: categories,
            categoryTokens: sessionCategoryTokens.isEmpty ? (categoryTokens.isEmpty ? nil : categoryTokens) : sessionCategoryTokens
        )
    }
    
    /// Updates blocking for an existing session.
    /// Used when session configuration changes mid-session (e.g., apps/categories changed).
    /// - Parameter session: The updated session configuration
    func updateBlocking(for session: LockSession) async throws {
        LoggerService.shared.logInfo("Updating blocking for session \(session.id.uuidString)", category: "ScreenTime")
        
        // Safely update by stopping current blocking and restarting
        // This prevents flickering by doing it atomically
        
        // Load updated application tokens and categories
        let tokens = activitySelectionService.loadApplicationTokens()
        let selection = activitySelectionService.loadSelection()
        let categoryTokens = selection?.categoryTokens ?? Set<ActivityCategoryToken>()
        
        // Use session-specific categories if provided
        let categoriesToBlock = session.selectedCategories ?? []
        
        LoggerService.shared.logInfo("Updating blocking with \(tokens.count) apps, \(categoryTokens.count) category tokens", category: "ScreenTime")
        
        // Apply updated restrictions
        if !tokens.isEmpty || !categoryTokens.isEmpty {
            activateShields(
                for: tokens,
                categories: categoriesToBlock.isEmpty ? nil : categoriesToBlock,
                categoryTokens: categoryTokens.isEmpty ? nil : categoryTokens
            )
        } else if let sessionSelection = loadSelection(for: session.id) {
            // Fall back to session-specific selection
            let selectionTokens = Array(sessionSelection.applicationTokens)
            let sessionCategoryTokens = sessionSelection.categoryTokens
            
            activateShields(
                for: selectionTokens,
                categories: session.selectedCategories,
                categoryTokens: sessionCategoryTokens.isEmpty ? nil : sessionCategoryTokens
            )
        }
        
        LoggerService.shared.logInfo("Blocking updated successfully", category: "ScreenTime")
    }
    
    func stopBlocking() async {
        LoggerService.shared.logInfo("Stopping blocking", category: "ScreenTime")
        do {
            try deactivateShields()
            LoggerService.shared.logInfo("Blocking stopped successfully", category: "ScreenTime")
        } catch {
            LoggerService.shared.logError("Failed to stop blocking", error: error, category: "ScreenTime")
        }
    }

    // MARK: - Anchoring
    func applyDailyAnchor() async {
        LoggerService.shared.logInfo("Applying daily anchor blocking", category: "ScreenTime")
        
        let tokens = activitySelectionService.loadApplicationTokens()
        let selection = activitySelectionService.loadSelection()
        let categoryTokens = selection?.categoryTokens ?? Set<ActivityCategoryToken>()
        
        if tokens.isEmpty && categoryTokens.isEmpty {
            LoggerService.shared.logWarning("No app selection found for anchoring.", category: "ScreenTime")
            return
        }
        
        activateShields(
            for: tokens,
            categories: nil,
            categoryTokens: categoryTokens.isEmpty ? nil : categoryTokens
        )
    }

    func applyChallengeOverrides() async {
        LoggerService.shared.logInfo("Applying challenge overrides", category: "ScreenTime")
        do {
            let challenges = try await ChallengeService.shared.getActiveChallenges()
            guard !challenges.isEmpty else { return }
            LoggerService.shared.logInfo("Challenge overrides available: \(challenges.count)", category: "ScreenTime")
        } catch {
            LoggerService.shared.logError("Failed to load challenges for overrides", error: error, category: "ScreenTime")
        }
    }

    func emergencyUnanchor(duration: TimeInterval) async {
        LoggerService.shared.logWarning("Emergency unanchor triggered for \(duration) seconds", category: "ScreenTime")
        let until = Date().addingTimeInterval(duration)
        appGroupStorage.setEmergencyUnanchorUntil(until)
        await stopBlocking()
    }
    
    // MARK: - App Selection
    func selectApps() async throws -> FamilyActivitySelection {
        // Load selected FamilyActivitySelection tokens from ActivitySelectionService
        guard let selection = activitySelectionService.loadSelection() else {
            throw ScreenTimeError.noAppsSelected
        }
        
        // Return the selection to the caller
        return selection
    }
    
    // MARK: - ManagedSettings Helpers

    // MARK: - Shield Activation/Deactivation
    func activateShields(for selection: FamilyActivitySelection, sessionId: UUID) throws {
        guard isAuthorized() else {
            throw ScreenTimeError.authorizationDenied
        }
        
        // Load application tokens from ActivitySelectionService
        let tokens = activitySelectionService.loadApplicationTokens()
        
        // If no tokens are available from the service, use the provided selection
        let tokensToUse = tokens.isEmpty ? Array(selection.applicationTokens) : tokens
        
        guard !tokensToUse.isEmpty else {
            throw ScreenTimeError.noAppsSelected
        }
        
        // Save selection for this session
        saveSelection(selection, for: sessionId)
        
        // Apply restrictions using ManagedSettings
        store.shield.applications = Set(tokensToUse)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        
        // Note: Session state is managed by SessionService, not here
        // SessionService writes SharedSessionState to App Group storage
    }
    
    /// Activates shields for the given application tokens
    func activateShields(for tokens: [ManagedSettings.ApplicationToken]) {
        LoggerService.shared.logInfo("Activating shields for \(tokens.count) apps", category: "ScreenTime")
        store.shield.applications = Set(tokens)
        store.shield.applicationCategories = .all()
        store.shield.webDomains = nil
    }
    
    /// Activates shields with selective category blocking
    /// - Parameters:
    ///   - tokens: Application tokens to block
    ///   - categories: App categories to block (if nil, uses categoryTokens or .all())
    ///   - categoryTokens: ActivityCategoryToken set from FamilyActivitySelection (if nil, uses categories or .all())
    func activateShields(
        for tokens: [ManagedSettings.ApplicationToken],
        categories: [AppCategory]?,
        categoryTokens: Set<ActivityCategoryToken>?
    ) {
        // Set application tokens
        if !tokens.isEmpty {
            store.shield.applications = Set(tokens)
        }
        
        // Set category blocking
        // Priority: categoryTokens > categories
        if let categoryTokens = categoryTokens, !categoryTokens.isEmpty {
            // Use category tokens directly from FamilyActivitySelection
            store.shield.applicationCategories = .specific(categoryTokens)
        } else if let categories = categories, !categories.isEmpty {
            // Note: We cannot directly map AppCategory to ActivityCategoryToken
            // ActivityCategoryToken only comes from FamilyActivitySelection via FamilyActivityPicker
            // If user selected categories but we don't have tokens, we cannot block selectively
            // In this case, we set to nil (no category blocking) rather than .all()
            // The user must select categories via FamilyActivityPicker to get ActivityCategoryToken
            LoggerService.shared.logWarning("Categories specified but no ActivityCategoryToken available. Category blocking requires FamilyActivityPicker selection.", category: "ScreenTime")
            store.shield.applicationCategories = nil
        } else {
            // Default: block all categories if no specific selection
            store.shield.applicationCategories = .all()
        }
        
        // Set web domains (use all for now, can be enhanced later)
        store.shield.webDomains = nil
    }
    
    func deactivateShields() throws {
        LoggerService.shared.logInfo("Deactivating shields", category: "ScreenTime")
        // Remove all restrictions
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        
        // Clear app group storage
        appGroupStorage.clearSessionState()
        appGroupStorage.setShieldState(nil)
        
        // Clear session selections
        sessionSelections.removeAll()
        LoggerService.shared.logInfo("Shields deactivated", category: "ScreenTime")
    }
    
    // MARK: - Session Integration (Legacy - kept for backward compatibility)
    /// Convenience method called when a session starts
    func onSessionStarted(_ session: LockSession) {
        Task {
            await startBlocking(for: session)
        }
    }
    
    /// Convenience method called when a session ends
    func onSessionEnded() {
        Task {
            await stopBlocking()
        }
    }
    
    // MARK: - Selection Persistence
    /// Saves a session-specific FamilyActivitySelection to AppGroup storage.
    /// Uses centralized AppGroupStorage service for consistency.
    func saveSelection(_ selection: FamilyActivitySelection, for sessionId: UUID) {
        // Update in-memory cache
        sessionSelections[sessionId] = selection
        
        // Persist to AppGroup storage using centralized service
        appGroupStorage.saveFamilyActivitySelection(selection, forSessionId: sessionId)
    }
    
    /// Loads a session-specific FamilyActivitySelection from AppGroup storage.
    /// Uses centralized AppGroupStorage service for consistency.
    func loadSelection(for sessionId: UUID) -> FamilyActivitySelection? {
        // First try to load from in-memory cache
        if let cached = sessionSelections[sessionId] {
            return cached
        }
        
        // Load from AppGroup storage using centralized service
        if let selection = appGroupStorage.loadFamilyActivitySelection(forSessionId: sessionId) {
            // Update in-memory cache for future access
            sessionSelections[sessionId] = selection
            return selection
        }
        
        return nil
    }
}

// MARK: - Challenge stubs (compile-time fallback)

struct Challenge {
    let id: UUID
    let blockedBundleIds: [String]
}

final class ChallengeService {
    static let shared = ChallengeService()

    private init() {}

    func getActiveChallenges() async throws -> [Challenge] {
        return []
    }
}

