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
                .font(AppTypography.sectionHeader).fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
        )
        .background(AppColors.background)
    }
}

struct SettingsScreen: View {
    var body: some View {
        Color.clear.overlay(
            Text("Settings")
                .font(AppTypography.sectionHeader).fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
        )
        .background(AppColors.background)
    }
}
