import Foundation
import FamilyControls
import Combine

@MainActor
class SelectAppsViewModel: ObservableObject {
    @Published var selectedAppTokens: [String] = []
    @Published var selection: FamilyActivitySelection = FamilyActivitySelection()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let tokensStorageKey = "selectedAppTokens"
    private let selectionStorageKey = "familyActivitySelection"
    
    init() {
        loadSelection()
    }
    
    private func loadSelection() {
        // Load FamilyActivitySelection
        if let data = UserDefaults.standard.data(forKey: selectionStorageKey),
           let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = decoded
            // Derive token identifiers from the selection
            selectedAppTokens = Array(decoded.applicationTokens).enumerated().map { index, _ in
                "app_token_\(index)"
            }
        } else {
            selection = FamilyActivitySelection()
            selectedAppTokens = []
        }
    }
    
    private func saveSelection() {
        // Save FamilyActivitySelection
        if let encoded = try? JSONEncoder().encode(selection) {
            UserDefaults.standard.set(encoded, forKey: selectionStorageKey)
        }
        // Save token identifiers as strings
        if let tokensEncoded = try? JSONEncoder().encode(selectedAppTokens) {
            UserDefaults.standard.set(tokensEncoded, forKey: tokensStorageKey)
        }
    }
    
    func updateSelection(from selection: FamilyActivitySelection) {
        self.selection = selection
        // Convert ApplicationToken array to String identifiers
        selectedAppTokens = Array(selection.applicationTokens).enumerated().map { index, token in
            // Use a simple identifier based on index and token hash
            let tokenHash = token.hashValue
            return "app_\(index)_\(abs(tokenHash) % 10000)"
        }
        saveSelection()
    }
    
    func clearSelection() {
        selectedAppTokens = []
        selection = FamilyActivitySelection()
        saveSelection()
    }
}

