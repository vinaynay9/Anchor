import SwiftUI
import Combine

class SessionViewModel: ObservableObject {
    @Published var activeSession: LockSession?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var timeRemaining: TimeInterval?
    
    private let sessionService = SessionService.shared
    private let screenTimeService = ScreenTimeService.shared
    private var timer: Timer?
    
    func loadActiveSession() {
        isLoading = true
        
        Task {
            do {
                let session = try await sessionService.getActiveSession()
                await MainActor.run {
                    self.activeSession = session
                    self.updateTimeRemaining()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func startSession(
        appsBlocked: [String],
        accountabilityPartnerId: UUID?,
        duration: TimeInterval?
    ) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Request Screen Time authorization if needed
                if !screenTimeService.isAuthorized() {
                    try await screenTimeService.requestAuthorization()
                }
                
                // Select apps to block
                let selection = try await screenTimeService.selectApps()
                
                // Create session
                let session = try await sessionService.createSession(
                    appsBlocked: appsBlocked,
                    accountabilityPartnerId: accountabilityPartnerId,
                    duration: duration
                )
                
                // Activate shields
                try screenTimeService.activateShields(for: selection, sessionId: session.id)
                
                await MainActor.run {
                    self.activeSession = session
                    self.updateTimeRemaining()
                    self.isLoading = false
                    self.startTimer()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func endSession() {
        guard let session = activeSession else { return }
        
        Task {
            do {
                try screenTimeService.deactivateShields()
                try await sessionService.endSession(id: session.id)
                
                await MainActor.run {
                    self.activeSession = nil
                    self.timeRemaining = nil
                    self.stopTimer()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func updateTimeRemaining() {
        guard let session = activeSession,
              let endTime = session.endTime else {
            timeRemaining = nil
            return
        }
        
        let remaining = endTime.timeIntervalSinceNow
        timeRemaining = remaining > 0 ? remaining : 0
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimeRemaining()
            if let remaining = self?.timeRemaining, remaining <= 0 {
                self?.endSession()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

