import Foundation
import Shared
import FamilyControls
import ManagedSettings

// Import the protocol (defined in ScreenTimeServiceProtocol.swift)
// The protocol is defined separately to avoid FamilyControls dependency in the protocol

// MARK: - Screen Time Service
// Handles all FamilyControls and ManagedSettings interactions

enum ScreenTimeError: Error {
    case authorizationDenied
    case authorizationFailed
    case noAppsSelected
    case shieldConfigurationFailed
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
    func requestAuthorization() async throws {
        do {
            try await authorizationCenter.requestAuthorization(for: .individual)
        } catch {
            throw ScreenTimeError.authorizationFailed
        }
    }
    
    func getAuthorizationStatus() -> ScreenTimeAuthorizationStatus {
        switch authorizationCenter.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .approved:
            return .approved
        @unknown default:
            return .notDetermined
        }
    }
    
    func isAuthorized() -> Bool {
        authorizationCenter.authorizationStatus == .approved
    }
    
    // MARK: - Protocol Implementation
    func startBlocking(for session: LockSession) async {
        // First try to load from ActivitySelectionService (persisted selection)
        let tokens = activitySelectionService.loadApplicationTokens()
        
        if !tokens.isEmpty {
            activateShields(for: tokens)
            return
        }
        
        // Fallback to session-specific selection
        guard let selection = loadSelection(for: session.id) else {
            return
        }
        
        let selectionTokens = Array(selection.applicationTokens)
        if !selectionTokens.isEmpty {
            activateShields(for: selectionTokens)
        }
    }
    
    func stopBlocking() async {
        try? deactivateShields()
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
        store.shield.webDomains = selection.webDomainTokens
        
        // Note: Session state is managed by SessionService, not here
        // SessionService writes SharedSessionState to App Group storage
    }
    
    /// Activates shields for the given application tokens
    func activateShields(for tokens: [ApplicationToken]) {
        store.shield.applications = .init(tokens)
        store.shield.applicationCategories = .all()
        store.shield.webDomains = .all()
    }
    
    func deactivateShields() throws {
        // Remove all restrictions
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        
        // Clear app group storage
        appGroupStorage.clearSessionState()
        
        // Clear session selections
        sessionSelections.removeAll()
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

