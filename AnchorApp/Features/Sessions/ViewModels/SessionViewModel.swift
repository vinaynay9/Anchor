import SwiftUI
import Combine
import Shared

@MainActor
class SessionViewModel: ObservableObject {
    @Published var activeSession: LockSession?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedDurationMinutes: Int = 25
    @Published var selectedFriendIds: [String] = []
    
    private let sessionService: SessionServiceProtocol
    private let screenTimeService: ScreenTimeServiceProtocol
    
    init(
        sessionService: SessionServiceProtocol = SessionService.shared,
        screenTimeService: ScreenTimeServiceProtocol = MockScreenTimeService.shared
    ) {
        self.sessionService = sessionService
        self.screenTimeService = screenTimeService
    }
    
    // MARK: - Notification Callbacks (UI-only wiring)
    
    /// Callback for when session ends - can be called from UI or notification handlers
    func onSessionEnded() {
        // Refresh active session state
        loadActiveSession()
        
        // Show UI feedback (toast will be shown by NotificationService if notifications disabled)
        // This is a UI-only callback for additional UI updates if needed
    }
    
    /// Callback for when session expires - can be called from UI or notification handlers
    func onSessionExpired() {
        // Refresh active session state
        loadActiveSession()
        
        // Show UI feedback (toast will be shown by NotificationService if notifications disabled)
        // This is a UI-only callback for additional UI updates if needed
    }
    
    func loadActiveSession() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                self.activeSession = try await sessionService.getActiveSession()
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func startSession() async {
        isLoading = true
        errorMessage = nil
        
        // Check Screen Time authorization
        guard screenTimeService.isAuthorized() else {
            // Request authorization if not already granted
            do {
                try await screenTimeService.requestAuthorization()
                
                // Verify authorization was granted
                guard screenTimeService.isAuthorized() else {
                    self.errorMessage = "Screen Time authorization is required to start a session."
                    self.isLoading = false
                    return
                }
            } catch {
                self.errorMessage = "Failed to get Screen Time authorization: \(error.localizedDescription)"
                self.isLoading = false
                return
            }
        }
        
        // Authorization granted, proceed with starting session
        do {
            let session = try await sessionService.startSession(
                durationMinutes: selectedDurationMinutes,
                friendIds: selectedFriendIds
            )
            self.activeSession = session
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    func endSession() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await sessionService.endSession()
                self.activeSession = nil
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

