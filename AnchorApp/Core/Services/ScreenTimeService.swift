import Foundation
import FamilyControls
import ManagedSettings

// MARK: - Screen Time Service
// Handles all FamilyControls and ManagedSettings interactions

enum ScreenTimeError: Error {
    case authorizationDenied
    case authorizationFailed
    case noAppsSelected
    case shieldConfigurationFailed
}

protocol ScreenTimeServiceProtocol {
    func requestAuthorization() async throws
    func isAuthorized() -> Bool
    func selectApps() async throws -> FamilyActivitySelection
    func activateShields(for selection: FamilyActivitySelection, sessionId: UUID) throws
    func deactivateShields() throws
    func saveSelection(_ selection: FamilyActivitySelection, for sessionId: UUID)
    func loadSelection(for sessionId: UUID) -> FamilyActivitySelection?
}

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
    
    func isAuthorized() -> Bool {
        authorizationCenter.authorizationStatus == .approved
    }
    
    // MARK: - App Selection
    func selectApps() async throws -> FamilyActivitySelection {
        // TODO: Present FamilyActivityPicker
        // This requires a UI component that can be presented modally
        // For now, return an empty selection
        
        // In actual implementation:
        // 1. Create a FamilyActivityPicker view
        // 2. Present it modally
        // 3. Wait for user selection
        // 4. Return the selection
        
        throw ScreenTimeError.noAppsSelected
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
    
    // MARK: - Blocking Control
    /// Starts blocking for the given session by reading tokens from ActivityPicker selection storage
    func startBlocking(for session: LockSession) {
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
    
    /// Stops blocking by deactivating shields
    func stopBlocking() {
        try? deactivateShields()
    }
    
    // MARK: - Session Integration
    /// Convenience method called when a session starts
    func onSessionStarted(_ session: LockSession) {
        startBlocking(for: session)
    }
    
    /// Convenience method called when a session ends
    func onSessionEnded() {
        stopBlocking()
    }
    
    // MARK: - Selection Persistence
    func saveSelection(_ selection: FamilyActivitySelection, for sessionId: UUID) {
        sessionSelections[sessionId] = selection
        
        // TODO: Persist to UserDefaults or file storage
        // FamilyActivitySelection can be encoded/decoded
    }
    
    func loadSelection(for sessionId: UUID) -> FamilyActivitySelection? {
        return sessionSelections[sessionId]
    }
}

