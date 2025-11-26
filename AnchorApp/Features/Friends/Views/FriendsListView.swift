import SwiftUI
import Shared

struct FriendsListView: View {
    @StateObject private var viewModel = FriendsViewModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.friends) { friend in
                    FriendRowView(friend: friend)
                }
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: AddFriendView()) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                viewModel.loadFriends()
            }
        }
    }
}

struct FriendRowView: View {
    let friend: Friend
    
    var body: some View {
        HStack {
            Circle()
                .fill(AppColors.primary.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(friend.friend?.username.prefix(1).uppercased() ?? "?")
                        .font(AppTypography.title3)
                )
            
            VStack(alignment: .leading) {
                Text(friend.friend?.username ?? "Unknown")
                    .font(AppTypography.bodyBold)
                Text(friend.friend?.displayName ?? "")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
        }
        .padding(.vertical, Theme.spacing)
    }
}

