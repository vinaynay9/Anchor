import SwiftUI
import Shared

/// Coordinator for the main tab-based navigation flow
@MainActor
class MainTabFlow: Coordinator, SheetPresenting {
    @Published var path = NavigationPath()
    @Published var presentedSheet: SheetDestination?
    
    // Navigation paths for each tab (3 tabs: Home, Friends, Settings)
    @Published var sessionsPath = NavigationPath()  // Home tab navigation
    @Published var friendsPath = NavigationPath()    // Friends tab navigation (includes unlock requests)
    @Published var settingsPath = NavigationPath()  // Settings tab navigation
    
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
    
    // MARK: - Requests Navigation (now part of Friends tab)
    
    func navigateToUnlockRequestDetail(request: UnlockRequest) {
        friendsPath.append(request)
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

