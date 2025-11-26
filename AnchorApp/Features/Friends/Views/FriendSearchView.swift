import SwiftUI

struct FriendSearchView: View {
    @State private var query: String = ""
    
    var body: some View {
        VStack {
            TextField("Search", text: $query)
                .textFieldStyle(AppTextFieldStyle())
                .padding()
            
            // TODO: Display search results
        }
        .navigationTitle("Search Friends")
    }
}

