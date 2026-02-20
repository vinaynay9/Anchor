import SwiftUI
import Shared

struct MainTabView: View {
    @EnvironmentObject var coordinator: MainTabFlow
    @State private var previousTab = 0
    @State private var isAnchored = false
    @State private var didSetInitialTab = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            TabView(selection: $coordinator.selectedTab) {
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

                // Tab 1: Goals
                NavigationStack {
                    GoalsListView()
                }
                .tabItem {
                    Label("Goals", systemImage: "checklist")
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
                            } else if destination == "inviteFriends" {
                                InviteFriendsView()
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
            .tint(AppColors.accent)
            .sheet(item: $coordinator.presentedSheet) { sheet in
                switch sheet {
                case .createSession:
                    SessionSetupView(viewModel: SessionViewModel())
                case .selectApps:
                    SelectAppsView()
                }
            }
            
            if isAnchored {
                anchoredStatusPill
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            refreshAnchoredState()
        }
        .onReceive(NotificationCenter.default.publisher(for: .appGroupDidUpdate)) { notification in
            if let key = notification.object as? String, key == AppGroupStorageKey.shieldState.rawValue {
                refreshAnchoredState()
            }
        }
        .onChange(of: coordinator.selectedTab) { newTab in
            if newTab != previousTab {
                HapticFeedback.soft()
                previousTab = newTab
            }
        }
        .motion(AppMotion.standard, reduceMotion: reduceMotion, value: isAnchored)
    }
    
    private var anchoredStatusPill: some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(AppTypography.caption).fontWeight(.semibold)
                Text("Anchored")
                    .font(AppTypography.caption)
            }
            .foregroundColor(AppColors.onPrimary)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                Capsule()
                    .fill(AppColors.primary.opacity(0.9))
                    .overlay(
                        Capsule()
                            .stroke(AppColors.border.opacity(0.4), lineWidth: 1)
                    )
            )
            .padding(.top, 12)
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .allowsHitTesting(false)
    }
    
    private func refreshAnchoredState() {
        let shieldState = AppGroupStorage.shared.getShieldState()
        isAnchored = shieldState?.isBlocking ?? false

        if !didSetInitialTab {
            coordinator.selectedTab = isAnchored ? 1 : 0
            didSetInitialTab = true
        } else if isAnchored {
            coordinator.selectedTab = 1
        }
    }
}
