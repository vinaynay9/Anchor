import Foundation
import SwiftUI
import Combine
import Shared

@MainActor
class UnlockRequestViewModel: ObservableObject {
    @Published var reason: String = ""
    @Published var isConfirmed: Bool = false
    @Published var isSending: Bool = false
    @Published var errorMessage: String?
    
    private let maxLength = 200
    private let unlockRequestService: UnlockRequestServiceProtocol
    private let sessionService: SessionServiceProtocol
    
    init(
        unlockRequestService: UnlockRequestServiceProtocol = UnlockRequestService.shared,
        sessionService: SessionServiceProtocol = SessionService.shared
    ) {
        self.unlockRequestService = unlockRequestService
        self.sessionService = sessionService
    }
    
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
        errorMessage = nil
        
        Task {
            do {
                // Get active session to retrieve session ID
                guard let activeSession = try await sessionService.getActiveSession() else {
                    await MainActor.run {
                        self.errorMessage = "No active session found"
                        self.isSending = false
                    }
                    return
                }
                
                // Send unlock request with real service call
                try await unlockRequestService.sendUnlockRequest(
                    sessionId: activeSession.id.uuidString,
                    reason: reason.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                
                await MainActor.run {
                    self.isConfirmed = true
                    self.isSending = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isSending = false
                }
            }
        }
    }
    
    func reset() {
        reason = ""
        isConfirmed = false
        isSending = false
        errorMessage = nil
    }
    
    // MARK: - Notification Callbacks (UI-only wiring)
    
    /// Callback for when unlock request is approved - can be called from UI or notification handlers
    func onUnlockRequestApproved() {
        // Reset the form since request was approved
        reset()
        
        // Show UI feedback (toast will be shown by NotificationService if notifications disabled)
        // This is a UI-only callback for additional UI updates if needed
    }
    
    /// Callback for when unlock request is rejected - can be called from UI or notification handlers
    func onUnlockRequestRejected() {
        // Keep the form state but clear confirmation
        isConfirmed = false
        
        // Show UI feedback (toast will be shown by NotificationService if notifications disabled)
        // This is a UI-only callback for additional UI updates if needed
    }
}

