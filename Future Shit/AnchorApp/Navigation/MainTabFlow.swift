import SwiftUI
import Shared

/// Coordinator for the main tab-based navigation flow
@MainActor
class MainTabFlow: Coordinator, SheetPresenting {
    @Published var path = NavigationPath()
    @Published var presentedSheet: SheetDestination?
    
    // Navigation paths for each tab (4 tabs: Home, Insights, Friends, Settings)
    @Published var sessionsPath = NavigationPath()  // Home tab navigation
    @Published var insightsPath = NavigationPath()   // Insights tab navigation
    @Published var friendsPath = NavigationPath()    // Friends tab navigation (includes unlock requests)
    @Published var settingsPath = NavigationPath()  // Settings tab navigation
    
    // Tab selection (0: Home, 1: Insights, 2: Friends, 3: Settings)
    @Published var selectedTab: Int = 0
    
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
    
    func navigateToUnlockRequestSubmit(session: LockSession) {
        // Navigate to unlock request submission in the friends tab
        selectedTab = 2 // Switch to Friends tab
        friendsPath.append("unlockRequestSubmit_\(session.id.uuidString)")
    }
    
    // MARK: - Settings Navigation
    
    func navigateToScreenTimeSettings() {
        settingsPath.append("screenTimeSettings")
    }
    
    func navigateToNotificationSettings() {
        settingsPath.append("notificationSettings")
    }
    
    // MARK: - Insights Navigation
    
    func navigateToInsights() {
        selectedTab = 1 // Switch to Insights tab
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

