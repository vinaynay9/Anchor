import SwiftUI
import Shared

struct MainTabView: View {
    @EnvironmentObject var coordinator: MainTabFlow
    @State private var previousTab = 0
    @State private var isAnchored = false
    
    var body: some View {
        ZStack {
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
                
                // Tab 1: Insights
                NavigationStack(path: $coordinator.insightsPath) {
                    InsightsView()
                }
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }
                .tag(1)
                
                // Tab 2: Friends (combines Friends + Unlock Requests)
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
                .tag(2)
                
                // Tab 3: Settings
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
                .tag(3)
            }
            .disabled(isAnchored)
            .overlay(
                AppColors.backgroundAnchored
                    .opacity(isAnchored ? 0.25 : 0.0)
                    .ignoresSafeArea()
            )
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
            
            if isAnchored {
                anchoredStatusPill
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            refreshAnchoredState()
        }
        .onReceive(NotificationCenter.default.publisher(for: .appGroupDidUpdate)) { notification in
            if let key = notification.object as? String, key == AppGroupStorageKey.sharedSessionState.rawValue {
                refreshAnchoredState()
            }
        }
        .onChange(of: coordinator.selectedTab) { newTab in
            if newTab != previousTab {
                HapticFeedback.soft()
                previousTab = newTab
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isAnchored)
    }
    
    private var anchoredStatusPill: some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("Anchored")
                    .font(AppTypography.captionBold)
            }
            .foregroundColor(AppColors.onPrimary)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                Capsule()
                    .fill(AppColors.primaryAnchored.opacity(0.9))
                    .overlay(
                        Capsule()
                            .stroke(AppColors.accentFocus.opacity(0.4), lineWidth: 1)
                    )
            )
            .padding(.top, 12)
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .allowsHitTesting(false)
    }
    
    private func refreshAnchoredState() {
        let sharedState = AppGroupStorage.shared.getSessionState()
        isAnchored = sharedState?.isActive ?? false
    }
}
