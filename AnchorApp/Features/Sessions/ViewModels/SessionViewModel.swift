import SwiftUI
import Combine

@MainActor
class SessionViewModel: ObservableObject {
    @Published var activeSession: LockSession?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedDurationMinutes: Int = 25
    @Published var selectedFriendIds: [String] = []
    
    private let sessionService: SessionServiceProtocol
    
    init(sessionService: SessionServiceProtocol = SessionService.shared) {
        self.sessionService = sessionService
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
        guard ScreenTimeService.shared.isAuthorized() else {
            // Request authorization if not already granted
            do {
                try await ScreenTimeService.shared.requestAuthorization()
                
                // Verify authorization was granted
                guard ScreenTimeService.shared.isAuthorized() else {
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

