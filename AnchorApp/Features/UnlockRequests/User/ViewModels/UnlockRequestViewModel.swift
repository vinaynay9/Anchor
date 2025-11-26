import Foundation
import SwiftUI
import Combine

@MainActor
class UnlockRequestViewModel: ObservableObject {
    @Published var reason: String = ""
    @Published var isConfirmed: Bool = false
    @Published var isSending: Bool = false
    
    private let maxLength = 200
    
    var characterCount: Int {
        reason.count
    }
    
    var isReasonValid: Bool {
        !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && reason.count <= maxLength
    }
    
    var canSend: Bool {
        isReasonValid && !isSending
    }
    
    func sendRequest() {
        guard canSend else { return }
        
        isSending = true
        
        // Simulate sending with async delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.isConfirmed = true
            self.isSending = false
        }
    }
    
    func reset() {
        reason = ""
        isConfirmed = false
        isSending = false
    }
}

