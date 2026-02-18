import SwiftUI
import Shared

/// Unified Friends tab view that combines Friends list and Unlock Requests
struct FriendsTabView: View {
    @EnvironmentObject var coordinator: MainTabFlow
    @State private var selectedSection: FriendsSection = .friends
    @StateObject private var friendsViewModel = FriendsViewModel()
    @StateObject private var requestsViewModel = UnlockRequestsViewModel()
    
    enum FriendsSection: String, CaseIterable {
        case friends = "Friends"
        case activity = "Activity"
        case requests = "Requests"
        
        var icon: String {
            switch self {
            case .friends: return "person.2"
            case .activity: return "bell.fill"
            case .requests: return "lock.open"
            }
        }
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Section Picker
                sectionPicker
                
                // Content based on selected section
                Group {
                    switch selectedSection {
                    case .friends:
                        FriendsSectionView(
                            viewModel: friendsViewModel,
                            coordinator: coordinator
                        )
                    case .activity:
                        ActivityFeedView()
                    case .requests:
                        RequestsSectionView(
                            viewModel: requestsViewModel,
                            coordinator: coordinator
                        )
                    }
                }
                .animation(Theme.springAnimation, value: selectedSection)
            }
        }
        .navigationTitle("Friends")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if selectedSection == .friends {
                    Button(action: {
                        withAnimation(Theme.springAnimationFast) {
                            coordinator.navigateToAddFriend()
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(AppTypography.bodyBold)
                            .foregroundColor(AppColors.anchorAccent)
                    }
                }
            }
        }
        .withGlobalToasts()
        .onAppear {
            friendsViewModel.loadFriends()
            requestsViewModel.loadPendingRequests()
            let sharedState = AppGroupStorage.shared.getSessionState()
            let userState: AnalyticsUserState = (sharedState?.isActive ?? false) ? .anchored : .free
            let payload = AnalyticsPayload(
                userState: userState,
                metrics: AnalyticsMetrics(stringValues: ["section": "friends_tab"])
            )
            AnalyticsServiceProvider.shared.log(event: .profileViewed, payload: payload)
        }
    }
    
    private var sectionPicker: some View {
        HStack(spacing: Theme.spacing) {
            ForEach(FriendsSection.allCases, id: \.self) { section in
                Button(action: {
                    withAnimation(Theme.springAnimationFast) {
                        selectedSection = section
                    }
                }) {
                    HStack(spacing: Theme.spacing) {
                        Image(systemName: section.icon)
                            .font(.system(size: 14, weight: .semibold))
                        Text(section.rawValue)
                            .font(AppTypography.subheadlineBold)
                    }
                    .foregroundColor(selectedSection == section ? AppColors.onPrimary : AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.spacing)
                    .background(
                        Group {
                            if selectedSection == section {
                                LinearGradient(
                                    colors: [
                                        AppColors.anchorAccent,
                                        AppColors.anchorPrimary
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            } else {
                                Color.clear
                            }
                        }
                    )
                    .cornerRadius(Theme.cornerRadius)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Theme.spacing)
        .background(AppColors.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusMedium)
        .padding(.horizontal, Theme.spacing2)
        .padding(.top, Theme.spacing)
    }
}

// MARK: - Friends Section View
struct FriendsSectionView: View {
    @ObservedObject var viewModel: FriendsViewModel
    @ObservedObject var coordinator: MainTabFlow
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            searchBar
                .padding(.horizontal, Theme.spacing2)
                .padding(.top, Theme.spacing)
                .padding(.bottom, Theme.spacing2)
            
            // Error Banner
            if let errorMessage = viewModel.errorMessage {
                ErrorBanner(message: errorMessage) {
                    viewModel.errorMessage = nil
                }
                .padding(.horizontal, Theme.spacing2)
                .padding(.bottom, Theme.spacing)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Content
            if viewModel.isLoading && viewModel.friends.isEmpty {
                ScrollView {
                    LazyVStack(spacing: Theme.spacing) {
                        ForEach(0..<3, id: \.self) { _ in
                            SkeletonRow()
                        }
                    }
                    .padding(.horizontal, Theme.spacing2)
                    .padding(.top, Theme.spacing2)
                }
            } else if viewModel.filteredFriends.isEmpty {
                emptyStateView
            } else {
                friendsList
            }
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: Theme.spacing) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)
                .font(AppTypography.body)
            
            TextField("Search friends…", text: $viewModel.searchQuery)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
                .textFieldStyle(SearchFieldStyle())
            
            if !viewModel.searchQuery.isEmpty {
                Button(action: {
                    withAnimation {
                        viewModel.searchQuery = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textSecondary)
                        .font(AppTypography.body)
                }
            }
        }
        .padding(Theme.spacing2)
        .background(AppColors.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusLarge)
    }
    
    private var friendsList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacing) {
                ForEach(viewModel.filteredFriends) { friend in
                    FriendCardView(friend: friend, onRemove: {
                        viewModel.removeFriend(friend)
                    })
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                        removal: .move(edge: .leading).combined(with: .opacity).combined(with: .scale(scale: 0.95))
                    ))
                }
            }
            .padding(.horizontal, Theme.spacing2)
            .padding(.bottom, Theme.spacing2)
        }
        .animation(Theme.springAnimation, value: viewModel.filteredFriends.count)
    }
    
    private var emptyStateView: some View {
        EmptyStateView(
            icon: viewModel.searchQuery.isEmpty ? "person.2.slash" : "magnifyingglass",
            title: viewModel.searchQuery.isEmpty ? "No friends yet" : "No friends found",
            message: viewModel.searchQuery.isEmpty
                ? "Start building your accountability network by adding friends"
                : "Try adjusting your search terms",
            actionTitle: viewModel.searchQuery.isEmpty ? "Add Friend" : nil,
            action: viewModel.searchQuery.isEmpty ? {
                coordinator.navigateToAddFriend()
            } : nil
        )
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

// MARK: - Requests Section View
struct RequestsSectionView: View {
    @ObservedObject var viewModel: UnlockRequestsViewModel
    @ObservedObject var coordinator: MainTabFlow
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.pendingRequests.isEmpty {
                LoadingView(message: "Loading requests...")
            } else if let errorMessage = viewModel.errorMessage, viewModel.pendingRequests.isEmpty {
                errorView(errorMessage)
            } else if viewModel.pendingRequests.isEmpty {
                emptyStateView
            } else {
                requestsList
            }
        }
    }
    
    private var requestsList: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(AppColors.error)
                    Text(errorMessage)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.error)
                    Spacer()
                    Button(action: {
                        viewModel.loadPendingRequests()
                    }) {
                        Text("Retry")
                            .font(AppTypography.captionBold)
                            .foregroundColor(AppColors.anchorAccent)
                    }
                }
                .padding()
                .background(AppColors.error.opacity(0.1))
                .cornerRadius(Theme.cornerRadius)
                .listRowBackground(AppColors.secondaryBackground)
            }
            
            ForEach(viewModel.pendingRequests) { request in
                Button(action: {
                    withAnimation(Theme.springAnimationFast) {
                        coordinator.navigateToUnlockRequestDetail(request: request)
                    }
                }) {
                    UnlockRequestRowView(request: request)
                }
                .buttonStyle(.plain)
            }
            
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.anchorAccent))
                    Spacer()
                }
                .padding()
                .listRowBackground(AppColors.secondaryBackground)
            }
        }
        .scrollContentBackground(.hidden)
        .animation(Theme.springAnimation, value: viewModel.pendingRequests.count)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: Theme.spacing2) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(AppColors.error)
            Text("Error loading requests")
                .font(AppTypography.title)
                .foregroundColor(AppColors.textPrimary)
            Text(message)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.spacing2)
            
            Button(action: {
                viewModel.loadPendingRequests()
            }) {
                Text("Retry")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, Theme.spacing)
        }
        .padding(Theme.spacing3)
    }
    
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "lock.open",
            title: "No unlock requests",
            message: "You don't have any pending unlock requests at the moment",
            actionTitle: nil,
            action: nil
        )
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}
