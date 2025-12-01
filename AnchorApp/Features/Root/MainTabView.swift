import SwiftUI
import Shared

struct MainTabView: View {
    @EnvironmentObject var coordinator: MainTabFlow
    @State private var selectedTab = 0
    @State private var previousTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 0: Home (Active Session)
            NavigationStack(path: $coordinator.sessionsPath) {
                SessionHomeView()
                    .navigationDestination(for: LockSession.self) { session in
                        ActiveSessionView(session: session, viewModel: SessionViewModel())
                    }
                    .navigationDestination(for: String.self) { destination in
                        if destination == "sessionSetup" {
                            SessionSetupView(viewModel: SessionViewModel())
                        } else {
                            EmptyView()
                        }
                    }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            // Tab 1: Friends (combines Friends + Unlock Requests)
            NavigationStack(path: $coordinator.friendsPath) {
                FriendsTabView()
                    .navigationDestination(for: Friend.self) { friend in
                        // Friend detail view would go here
                        Text("Friend Detail: \(friend.id.uuidString)")
                    }
                    .navigationDestination(for: UnlockRequest.self) { request in
                        UnlockRequestDetailView(request: request)
                    }
            }
            .tabItem {
                Label("Friends", systemImage: "person.2.fill")
            }
            .tag(1)
            
            // Tab 2: Settings
            NavigationStack(path: $coordinator.settingsPath) {
                SettingsView()
                    .navigationDestination(for: String.self) { destination in
                        if destination == "screenTimeSettings" {
                            ScreenTimePermissionView()
                        } else if destination == "notificationSettings" {
                            NotificationSettingsView()
                        } else {
                            EmptyView()
                        }
                    }
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(2)
        }
        .sheet(item: $coordinator.presentedSheet) { sheet in
            switch sheet {
            case .addFriend:
                AddFriendSheet(viewModel: FriendsViewModel())
            case .createSession:
                SessionSetupView(viewModel: SessionViewModel())
            case .selectApps:
                SelectAppsView()
            }
        }
        .onChange(of: selectedTab) { newTab in
            if newTab != previousTab {
                HapticFeedback.soft()
                previousTab = newTab
            }
        }
    }
}

