import SwiftUI

struct FriendListView: View {
    @StateObject private var viewModel = FriendListViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    searchBar
                        .padding(.horizontal, Theme.padding)
                        .padding(.top, Theme.spacing)
                        .padding(.bottom, Theme.spacing * 2)
                    
                    // Friends List
                    if viewModel.filteredFriends.isEmpty {
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
                            viewModel.isShowingAddSheet = true
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(AppTypography.bodyBold)
                            .foregroundColor(AppColors.accent)
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingAddSheet) {
                AddFriendSheet(viewModel: viewModel)
            }
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: Theme.spacing) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)
                .font(AppTypography.body)
            
            TextField("Search friends…", text: $viewModel.searchText)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !viewModel.searchText.isEmpty {
                Button(action: {
                    withAnimation {
                        viewModel.searchText = ""
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
        .cornerRadius(Theme.cornerRadius)
    }
    
    private var friendsList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacing) {
                ForEach(viewModel.filteredFriends) { friend in
                    FriendCardView(friend: friend, onRemove: {
                        viewModel.removeFriend(friend)
                    })
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            }
            .padding(.horizontal, Theme.padding)
            .padding(.bottom, Theme.padding)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Theme.spacing * 2) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textSecondary.opacity(0.5))
            
            Text(viewModel.searchText.isEmpty ? "No friends yet" : "No friends found")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textSecondary)
            
            if viewModel.searchText.isEmpty {
                Text("Tap + to add your first friend")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.padding * 2)
    }
}

struct FriendCardView: View {
    let friend: FriendMockModel
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: Theme.padding) {
            // Avatar with gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.primary,
                                AppColors.accent
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
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
                    .foregroundColor(AppColors.accentLight)
                    .padding(.horizontal, Theme.padding)
                    .padding(.vertical, Theme.spacing)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerRadius)
                            .stroke(AppColors.accentLight.opacity(0.5), lineWidth: 1.5)
                    )
            }
        }
        .padding(Theme.padding)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
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
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            AppColors.primary.opacity(0.3),
                            AppColors.accent.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

