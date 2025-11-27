import SwiftUI
import Shared

/// Coordinator for the main tab-based navigation flow
@MainActor
class MainTabFlow: Coordinator, SheetPresenting {
    @Published var path = NavigationPath()
    @Published var presentedSheet: SheetDestination?
    
    // Navigation paths for each tab
    @Published var sessionsPath = NavigationPath()
    @Published var friendsPath = NavigationPath()
    @Published var requestsPath = NavigationPath()
    @Published var settingsPath = NavigationPath()
    
    func start() {
        // Main tab flow starts with the tab view
    }
    
    // MARK: - Sessions Navigation
    
    func navigateToSessionSetup() {
        sessionsPath.append("sessionSetup")
    }
    
    func navigateToActiveSession(session: LockSession) {
        sessionsPath.append(session)
    }
    
    func navigateToSessionDetail(session: LockSession) {
        sessionsPath.append(session)
    }
    
    // MARK: - Friends Navigation
    
    func navigateToAddFriend() {
        presentedSheet = .addFriend
    }
    
    func navigateToFriendDetail(friend: Friend) {
        friendsPath.append(friend)
    }
    
    // MARK: - Requests Navigation
    
    func navigateToUnlockRequestDetail(request: UnlockRequest) {
        requestsPath.append(request)
    }
    
    // MARK: - Settings Navigation
    
    func navigateToScreenTimeSettings() {
        settingsPath.append("screenTimeSettings")
    }
    
    func navigateToNotificationSettings() {
        settingsPath.append("notificationSettings")
    }
    
    // MARK: - App Selection
    
    func navigateToSelectApps() {
        presentedSheet = .selectApps
    }
    
    var rootView: some View {
        MainTabView()
            .environmentObject(self)
    }
}

