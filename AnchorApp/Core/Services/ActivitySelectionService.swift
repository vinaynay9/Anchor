import Foundation
import FamilyControls

protocol ActivitySelectionServiceProtocol {
    func saveSelection(_ selection: FamilyActivitySelection) throws
    func loadSelection() -> FamilyActivitySelection?
    func loadApplicationTokens() -> [ApplicationToken]
    func clearSelection()
}

class ActivitySelectionService: ActivitySelectionServiceProtocol {
    static let shared = ActivitySelectionService()
    
    private let appGroupStorage = AppGroupStorage.shared
    private let appGroupIdentifier = AppConfig.appGroupIdentifier
    private let selectionKey = "familyActivitySelection"
    
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    private init() {}
    
    // MARK: - Save Selection
    
    func saveSelection(_ selection: FamilyActivitySelection) throws {
        guard let defaults = userDefaults else {
            throw ActivitySelectionError.storageUnavailable
        }
        
        // FamilyActivitySelection conforms to Codable, so we can encode it
        let encoder = JSONEncoder()
        do {
            let encoded = try encoder.encode(selection)
            defaults.set(encoded, forKey: selectionKey)
        } catch {
            throw ActivitySelectionError.encodingFailed(error)
        }
    }
    
    // MARK: - Load Selection
    
    func loadSelection() -> FamilyActivitySelection? {
        guard let defaults = userDefaults else {
            return nil
        }
        
        guard let data = defaults.data(forKey: selectionKey) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(FamilyActivitySelection.self, from: data)
        } catch {
            // If decoding fails, return nil
            return nil
        }
    }
    
    // MARK: - Load Application Tokens
    
    func loadApplicationTokens() -> [ApplicationToken] {
        guard let selection = loadSelection() else {
            return []
        }
        
        return Array(selection.applicationTokens)
    }
    
    // MARK: - Clear Selection
    
    func clearSelection() {
        guard let defaults = userDefaults else {
            return
        }
        
        defaults.removeObject(forKey: selectionKey)
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

