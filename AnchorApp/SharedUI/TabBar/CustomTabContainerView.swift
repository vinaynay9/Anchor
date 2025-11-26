import SwiftUI

struct CustomTabContainerView<Content: View>: View {
    @State private var selectedTab: TabItem = .home
    @ViewBuilder let content: (TabItem) -> Content
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content views
            Group {
                switch selectedTab {
                case .home:
                    content(.home)
                case .sessions:
                    content(.sessions)
                case .apps:
                    content(.apps)
                case .friends:
                    content(.friends)
                case .settings:
                    content(.settings)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
            
            // Custom tab bar
            CustomTabBarView(selectedTab: $selectedTab)
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
}

// MARK: - Dummy Screen Views

struct HomeScreen: View {
    var body: some View {
        Color.clear.overlay(
            Text("Home")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
        )
        .background(AppColors.background)
    }
}

struct SessionsScreen: View {
    var body: some View {
        Color.clear.overlay(
            Text("Sessions")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
        )
        .background(AppColors.background)
    }
}

struct AppsScreen: View {
    var body: some View {
        Color.clear.overlay(
            Text("Apps")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
        )
        .background(AppColors.background)
    }
}

struct FriendsScreen: View {
    var body: some View {
        Color.clear.overlay(
            Text("Friends")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
        )
        .background(AppColors.background)
    }
}

struct SettingsScreen: View {
    var body: some View {
        Color.clear.overlay(
            Text("Settings")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
        )
        .background(AppColors.background)
    }
}

