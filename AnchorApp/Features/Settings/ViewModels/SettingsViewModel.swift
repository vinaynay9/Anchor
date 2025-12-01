import SwiftUI
import Foundation

@MainActor
class SettingsViewModel: ObservableObject {
    // Notification toggles with @AppStorage
    @AppStorage("sessionRemindersEnabled") var sessionRemindersEnabled: Bool = true
    @AppStorage("unlockRequestAlertsEnabled") var unlockRequestAlertsEnabled: Bool = true
    @AppStorage("witnessRequestEnabled") var witnessRequestEnabled: Bool = true
    
    // Alert state
    @Published var showClearDataAlert = false
    
    // User info (mock for now - should come from AuthService)
    var userInitials: String {
        // TODO: Get from actual user data
        return "U"
    }
    
    var displayName: String {
        // TODO: Get from actual user data
        return "User"
    }
    
    var userEmail: String {
        // TODO: Get from actual user data
        return "user@example.com"
    }
    
    // Simulated actions
    func editProfile() {
        // Simulated action - no backend
        print("Edit Profile tapped")
    }
    
    func changeDisplayName() {
        // Simulated action - no backend
        print("Change Display Name tapped")
    }
    
    func clearLocalData() {
        showClearDataAlert = true
    }
    
    func confirmClearLocalData() {
        // Simulated action - no backend
        print("Clearing local data...")
        showClearDataAlert = false
        
        // Show success toast after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            ToastManager.shared.show("Data Cleared")
        }
    }
    
    func exportActivityLog() {
        // Simulated action - no backend
        print("Export Activity Log tapped")
    }
    
    func openPrivacyPolicy() {
        // Simulated action - no backend
        print("Privacy Policy tapped")
    }
    
    func openTerms() {
        // Simulated action - no backend
        print("Terms tapped")
    }
    
    func signOut() {
        // TODO: Integrate with AuthService
        Task {
            do {
                try await AuthService.shared.signOut()
                // Navigation will be handled by AppCoordinator
            } catch {
                print("Sign out error: \(error)")
            }
        }
    }
    
    func deleteAccount() {
        // TODO: Implement account deletion
        print("Delete Account tapped")
    }
    
    // Get app version
    var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0.0"
    }
}
