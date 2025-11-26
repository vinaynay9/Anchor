import SwiftUI
import Foundation

class ShieldViewModel: ObservableObject {
    @Published var message: String = "This app is blocked during your focus session."
    @Published var timeRemaining: TimeInterval?
    
    private let appGroupStorage = AppGroupStorage.shared
    
    func loadSessionState() {
        let state = appGroupStorage.getSessionState()
        
        if state.isActive {
            message = state.message ?? "This app is blocked during your focus session."
            timeRemaining = state.timeRemaining
        } else {
            message = "This app is blocked."
            timeRemaining = nil
        }
    }
}

