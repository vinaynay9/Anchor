import Foundation
import SwiftUI

// MARK: - Screen Time Permission View Model
@MainActor
class ScreenTimePermissionViewModel: ObservableObject {
    @Published var status: ScreenTimeAuthorizationStatus = .notDetermined
    @Published var isRequesting: Bool = false
    @Published var errorMessage: String?
    
    private let screenTimeService = ScreenTimeService.shared
    
    init() {
        checkStatus()
    }
    
    func checkStatus() {
        status = screenTimeService.getAuthorizationStatus()
    }
    
    func requestPermission() async {
        guard status != .approved else { return }
        
        isRequesting = true
        errorMessage = nil
        
        do {
            try await screenTimeService.requestAuthorization()
            status = screenTimeService.getAuthorizationStatus()
        } catch {
            errorMessage = "Failed to request authorization. Please try again."
            status = screenTimeService.getAuthorizationStatus()
        }
        
        isRequesting = false
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

