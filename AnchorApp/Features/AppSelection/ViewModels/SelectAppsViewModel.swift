import Foundation
import FamilyControls
import Combine
import Shared

@MainActor
class SelectAppsViewModel: ObservableObject {
    @Published var selectedAppTokens: [String] = []
    @Published var selection: FamilyActivitySelection = FamilyActivitySelection()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let activitySelectionService = ActivitySelectionService.shared
    
    init() {
        loadSelection()
    }
    
    /// Loads the FamilyActivitySelection from AppGroup storage via ActivitySelectionService.
    /// This ensures consistency with the rest of the app and makes the selection accessible to the Shield Extension.
    private func loadSelection() {
        if let loadedSelection = activitySelectionService.loadSelection() {
            selection = loadedSelection
            // Derive token identifiers from the selection
            selectedAppTokens = Array(loadedSelection.applicationTokens).enumerated().map { index, _ in
                "app_token_\(index)"
            }
        } else {
            selection = FamilyActivitySelection()
            selectedAppTokens = []
        }
    }
    
    /// Saves the FamilyActivitySelection to AppGroup storage via ActivitySelectionService.
    /// This ensures consistency with the rest of the app and makes the selection accessible to the Shield Extension.
    private func saveSelection() {
        do {
            try activitySelectionService.saveSelection(selection)
        } catch {
            errorMessage = "Failed to save app selection: \(error.localizedDescription)"
        }
    }
    
    /// Updates the selection and persists it to AppGroup storage.
    /// - Parameter selection: The new FamilyActivitySelection to save
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
    
    /// Clears the selection and removes it from AppGroup storage.
    func clearSelection() {
        selectedAppTokens = []
        selection = FamilyActivitySelection()
        activitySelectionService.clearSelection()
    }
}

