import Foundation
import Combine
import SwiftUI

@MainActor
class ActiveSessionMockViewModel: ObservableObject {
    @Published var remainingSeconds: Int = 1500 // 25 minutes in seconds
    @Published var isRunning: Bool = true
    
    let timer = Timer.publish(every: 1.0, on: .main, in: .common)
    private var cancellables = Set<AnyCancellable>()
    private let totalDuration: Int = 1500 // 25 minutes
    private var isTimerSubscribed = false
    
    init() {
        startTimer()
    }
    
    func startTimer() {
        guard !isTimerSubscribed else { return }
        isRunning = true
        isTimerSubscribed = true
        timer
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isRunning else { return }
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                } else {
                    Task { @MainActor in
                        self.stopTimer()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func stopTimer() {
        isRunning = false
        // Keep cancellables to maintain timer connection for potential restart
    }
    
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return Double(totalDuration - remainingSeconds) / Double(totalDuration)
    }
    
    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func endSession() {
        stopTimer()
        // Mock action - in real implementation, this would call a service
    }
    
    func submitProof() {
        // Mock action - in real implementation, this would navigate to proof capture
    }
    
    // No deinit work needed for mock view model
}
