import Foundation
import Shared
import FamilyControls

protocol ActivitySelectionServiceProtocol {
    func saveSelection(_ selection: FamilyActivitySelection) throws
    func loadSelection() -> FamilyActivitySelection?
    func loadApplicationTokens() -> [ApplicationToken]
    func loadCategoryTokens() -> Set<ActivityCategoryToken>
    func clearSelection()
}

class ActivitySelectionService: ActivitySelectionServiceProtocol {
    static let shared = ActivitySelectionService()
    
    private let appGroupStorage = AppGroupStorage.shared
    
    private init() {}
    
    // MARK: - Save Selection
    
    /// Saves the FamilyActivitySelection to AppGroup storage using centralized keys.
    /// This ensures the selection is accessible to both AnchorApp and Shield Extension.
    func saveSelection(_ selection: FamilyActivitySelection) throws {
        guard appGroupStorage.saveFamilyActivitySelection(selection, forKey: .familyActivitySelection) else {
            throw ActivitySelectionError.storageUnavailable
        }
    }
    
    // MARK: - Load Selection
    
    /// Loads the FamilyActivitySelection from AppGroup storage.
    /// Returns nil if no selection is stored or if decoding fails.
    func loadSelection() -> FamilyActivitySelection? {
        return appGroupStorage.loadFamilyActivitySelection(forKey: .familyActivitySelection)
    }
    
    // MARK: - Load Application Tokens
    
    /// Loads application tokens from the stored FamilyActivitySelection.
    /// Returns an empty array if no selection is stored.
    func loadApplicationTokens() -> [ApplicationToken] {
        guard let selection = loadSelection() else {
            return []
        }
        
        return Array(selection.applicationTokens)
    }
    
    // MARK: - Load Category Tokens
    
    /// Loads category tokens from the stored FamilyActivitySelection.
    /// Returns an empty set if no selection is stored.
    func loadCategoryTokens() -> Set<ActivityCategoryToken> {
        guard let selection = loadSelection() else {
            return []
        }
        
        return selection.categoryTokens
    }
    
    // MARK: - Clear Selection
    
    /// Clears the stored FamilyActivitySelection from AppGroup storage.
    func clearSelection() {
        appGroupStorage.clearFamilyActivitySelection(forKey: .familyActivitySelection)
    }
}

// MARK: - Errors

enum ActivitySelectionError: LocalizedError {
    case storageUnavailable
    case encodingFailed(Error)
    case decodingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .storageUnavailable:
            return "App group storage is not available"
        case .encodingFailed(let error):
            return "Failed to encode selection: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode selection: \(error.localizedDescription)"
        }
    }
}

