import SwiftUI
import Shared

struct PendingRequestsView: View {
    @StateObject private var viewModel = FriendsViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.friendRequests) { request in
                PendingRequestRowView(request: request, viewModel: viewModel)
            }
        }
        .navigationTitle("Pending Requests")
        .onAppear {
            viewModel.loadFriendRequests()
        }
    }
}

struct PendingRequestRowView: View {
    let request: Friend
    let viewModel: FriendsViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(request.friend?.username ?? "Unknown")
                    .font(AppTypography.bodyBold)
            }
            
            Spacer()
            
            Button("Accept") {
                viewModel.acceptFriendRequest(request)
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(width: 80)
        }
    }
}
