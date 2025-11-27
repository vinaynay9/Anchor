import Foundation
import SwiftUI

// MARK: - Mock Screen Time Authorization Status
enum MockScreenTimeAuthorizationStatus {
    case notDetermined
    case denied
    case approved
}

// MARK: - Screen Time Permission View Model
@MainActor
class ScreenTimePermissionViewModel: ObservableObject {
    @Published var status: MockScreenTimeAuthorizationStatus = .notDetermined
    
    func requestPermission() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.status = .approved
        }
    }
}

