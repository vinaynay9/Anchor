import Foundation
import SwiftUI

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var friends: [FriendMockModel] = []
    @Published var searchQuery: String = ""
    @Published var isShowingAddSheet = false
    @Published var addFriendText = ""
    @Published var showAddSuccess = false
    @Published var addError: String?
    
    private var allFriends: [FriendMockModel] = []
    
    init() {
        // Initialize with mock data
        allFriends = [
            FriendMockModel(displayName: "Alex Johnson", username: "@alexj"),
            FriendMockModel(displayName: "Sarah Chen", username: "@sarahc"),
            FriendMockModel(displayName: "Michael Brown", username: "@mikeb"),
            FriendMockModel(displayName: "Emma Davis", username: "@emmad"),
            FriendMockModel(displayName: "James Wilson", username: "@jamesw")
        ]
        friends = allFriends
    }
    
    var filteredFriends: [FriendMockModel] {
        if searchQuery.isEmpty {
            return friends
        }
        return friends.filter { friend in
            friend.displayName.localizedCaseInsensitiveContains(searchQuery) ||
            friend.username.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    func addFriend(_ name: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            withAnimation {
                addError = "Please enter a friend ID or username"
            }
            return
        }
        
        addError = nil
        
        // Create a new mock friend from the input
        let newFriend = FriendMockModel(
            displayName: name.trimmingCharacters(in: .whitespaces),
            username: "@\(name.trimmingCharacters(in: .whitespaces).lowercased())"
        )
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            friends.append(newFriend)
            allFriends.append(newFriend)
            showAddSuccess = true
        }
        
        // Reset after showing success
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                self.showAddSuccess = false
                self.addFriendText = ""
                self.isShowingAddSheet = false
            }
        }
    }
    
    func addFriend() {
        addFriend(addFriendText)
    }
    
    func removeFriend(_ friend: FriendMockModel) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            friends.removeAll { $0.id == friend.id }
            allFriends.removeAll { $0.id == friend.id }
        }
    }
}
