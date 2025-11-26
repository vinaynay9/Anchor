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
                let session = try await sessionService.getActiveSession()
                self.activeSession = session
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func startSession() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let session = try await sessionService.startSession(
                    durationMinutes: selectedDurationMinutes,
                    selectedFriendIds: selectedFriendIds
                )
                self.activeSession = session
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
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

