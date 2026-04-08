import SwiftUI
import Shared

/// Coordinator for the main tab-based navigation flow
@MainActor
class MainTabFlow: Coordinator, SheetPresenting {
    @Published var path = NavigationPath()
    @Published var presentedSheet: SheetDestination?
    
    // Navigation paths for each tab
    @Published var sessionsPath = NavigationPath()  // Session tab navigation
    @Published var settingsPath = NavigationPath()  // Settings tab navigation
    @Published var statsPath = NavigationPath()     // Stats tab navigation (future)

    // Tab selection (0: Session, 1: Goals, 2: Stats, 3: Settings)
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
    
    // MARK: - Settings Navigation
    
    func navigateToScreenTimeSettings() {
        settingsPath.append("screenTimeSettings")
    }
    
    func navigateToNotificationSettings() {
        settingsPath.append("notificationSettings")
    }

    func navigateToInviteFriends() {
        settingsPath.append("inviteFriends")
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
