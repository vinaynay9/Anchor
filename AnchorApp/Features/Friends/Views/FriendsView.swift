import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var coordinator: MainTabFlow
    @StateObject private var viewModel = FriendsViewModel()
    
    var body: some View {
        ZStack {
            AppColors.anchorPrimaryDark.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                    .padding(.horizontal, Theme.padding)
                    .padding(.top, Theme.spacing)
                    .padding(.bottom, Theme.spacing * 2)
                
                // Error Banner
                if let errorMessage = viewModel.errorMessage {
                    ErrorBanner(message: errorMessage) {
                        viewModel.errorMessage = nil
                    }
                    .padding(.bottom, Theme.spacing)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Content
                if viewModel.isLoading && viewModel.friends.isEmpty {
                    // Show skeleton loaders during initial load
                    ScrollView {
                        LazyVStack(spacing: Theme.spacing) {
                            ForEach(0..<3, id: \.self) { _ in
                                SkeletonRow()
                            }
                        }
                        .padding(.horizontal, Theme.padding)
                        .padding(.top, Theme.padding)
                    }
                } else if viewModel.filteredFriends.isEmpty {
                    emptyStateView
                } else {
                    friendsList
                }
            }
        }
        .navigationTitle("Friends")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        coordinator.navigateToAddFriend()
                    }
                }) {
                    Image(systemName: "plus")
                        .font(AppTypography.bodyBold)
                        .foregroundColor(AppColors.anchorAccent)
                }
            }
        }
        .withGlobalToasts()
        .onAppear {
            viewModel.loadFriends()
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
                .textFieldStyle(PlainTextFieldStyle())
            
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
        .padding(Theme.padding)
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppLayout.cardCornerRadius)
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
            .padding(.horizontal, Theme.padding)
            .padding(.bottom, Theme.padding)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.filteredFriends.count)
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

struct FriendCardView: View {
    let friend: FriendMockModel
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: Theme.padding) {
            // Avatar with gradient and lavender border
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.anchorPrimary,
                                AppColors.anchorAccent
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(AppColors.anchorLavender.opacity(0.6), lineWidth: 2)
                    )
                
                Text(friend.initials)
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            // Friend Info
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.displayName)
                    .font(AppTypography.bodyBold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(friend.username)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            // Remove Button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    onRemove()
                }
            }) {
                Text("Remove")
                    .font(AppTypography.captionBold)
                    .foregroundColor(AppColors.anchorLavender)
                    .padding(.horizontal, Theme.padding)
                    .padding(.vertical, Theme.spacing)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.buttonCornerRadius)
                            .stroke(AppColors.anchorLavender.opacity(0.5), lineWidth: 1.5)
                    )
            }
        }
        .padding(Theme.padding)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            AppColors.secondaryBackground,
                            AppColors.secondaryBackground.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            AppColors.anchorPrimary.opacity(0.3),
                            AppColors.anchorAccent.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

