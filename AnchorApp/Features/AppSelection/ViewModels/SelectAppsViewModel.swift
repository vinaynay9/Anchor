import Foundation
import FamilyControls
import Combine

@MainActor
class SelectAppsViewModel: ObservableObject {
    @Published var selection: FamilyActivitySelection = FamilyActivitySelection()
    @Published var applicationTokens: [ApplicationToken] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let activitySelectionService: ActivitySelectionServiceProtocol
    
    init(activitySelectionService: ActivitySelectionServiceProtocol = ActivitySelectionService.shared) {
        self.activitySelectionService = activitySelectionService
        loadSelection()
    }
    
    func loadSelection() {
        isLoading = true
        defer { isLoading = false }
        
        if let savedSelection = activitySelectionService.loadSelection() {
            selection = savedSelection
            applicationTokens = Array(savedSelection.applicationTokens)
        } else {
            selection = FamilyActivitySelection()
            applicationTokens = []
        }
    }
    
    func saveSelection() {
        isLoading = true
        errorMessage = nil
        
        do {
            try activitySelectionService.saveSelection(selection)
            applicationTokens = Array(selection.applicationTokens)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func updateSelection(_ newSelection: FamilyActivitySelection) {
        selection = newSelection
        applicationTokens = Array(newSelection.applicationTokens)
    }
}

