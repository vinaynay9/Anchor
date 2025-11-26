import SwiftUI

struct AddFriendView: View {
    @State private var searchQuery: String = ""
    @StateObject private var viewModel = FriendsViewModel()
    
    var body: some View {
        VStack {
            TextField("Search by username", text: $searchQuery)
                .textFieldStyle(AppTextFieldStyle())
                .padding()
            
            // TODO: Show search results
            
            Spacer()
        }
        .navigationTitle("Add Friend")
    }
}

