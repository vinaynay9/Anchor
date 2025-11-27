import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SessionHomeView()
                .tabItem {
                    Label("Sessions", systemImage: "lock.shield")
                }
                .tag(0)
            
            FriendsView()
                .tabItem {
                    Label("Friends", systemImage: "person.2")
                }
                .tag(1)
            
            IncomingRequestsListView()
                .tabItem {
                    Label("Requests", systemImage: "bell")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(3)
        }
    }
}

