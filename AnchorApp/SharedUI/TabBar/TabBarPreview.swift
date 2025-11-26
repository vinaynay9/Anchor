import SwiftUI

// MARK: - Preview Example
// This file demonstrates how to use the CustomTabContainerView

struct TabBarPreview: View {
    var body: some View {
        CustomTabContainerView { tab in
            switch tab {
            case .home:
                HomeScreen()
            case .sessions:
                SessionsScreen()
            case .apps:
                AppsScreen()
            case .friends:
                FriendsScreen()
            case .settings:
                SettingsScreen()
            }
        }
    }
}

#Preview {
    TabBarPreview()
}

