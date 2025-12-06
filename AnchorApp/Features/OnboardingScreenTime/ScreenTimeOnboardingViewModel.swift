import Foundation
import SwiftUI

@MainActor
class ScreenTimeOnboardingViewModel: ObservableObject {
    @Published var authorizationStatus: ScreenTimeAuthorizationStatus = .notDetermined
    @Published var isRequesting: Bool = false
    @Published var errorMessage: String?
    
    private let screenTimeService = ScreenTimeService.shared
    
    func checkAuthorizationStatus() async {
        authorizationStatus = screenTimeService.getAuthorizationStatus()
    }
    
    func requestAuthorization() async {
        guard authorizationStatus != .approved else { return }
        
        isRequesting = true
        errorMessage = nil
        
        do {
            try await screenTimeService.requestAuthorization()
            authorizationStatus = screenTimeService.getAuthorizationStatus()
        } catch {
            errorMessage = "Failed to request authorization. Please try again."
            authorizationStatus = screenTimeService.getAuthorizationStatus()
        }
        
        isRequesting = false
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

