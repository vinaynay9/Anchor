import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var coordinator: MainTabFlow
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
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
                Label("Sessions", systemImage: "lock.shield")
            }
            .tag(0)
            
            NavigationStack(path: $coordinator.friendsPath) {
                FriendsView()
                    .navigationDestination(for: Friend.self) { friend in
                        // Friend detail view would go here
                        Text("Friend Detail: \(friend.id.uuidString)")
                    }
            }
            .tabItem {
                Label("Friends", systemImage: "person.2")
            }
            .tag(1)
            
            NavigationStack(path: $coordinator.requestsPath) {
                IncomingRequestsListView()
                    .navigationDestination(for: UnlockRequest.self) { request in
                        UnlockRequestDetailView(request: request)
                    }
            }
            .tabItem {
                Label("Requests", systemImage: "bell")
            }
            .tag(2)
            
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
                Label("Settings", systemImage: "gearshape")
            }
            .tag(3)
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
    }
}

