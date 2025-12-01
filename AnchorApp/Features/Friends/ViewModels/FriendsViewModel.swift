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
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
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
    
    func loadFriends() {
        isLoading = true
        errorMessage = nil
        
        Task {
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Simulate potential error (10% chance for demo)
            if Int.random(in: 0..<10) == 0 {
                await MainActor.run {
                    self.errorMessage = "Failed to load friends. Please try again."
                    self.isLoading = false
                }
                return
            }
            
            await MainActor.run {
                self.friends = self.allFriends
                self.isLoading = false
            }
        }
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
            ToastManager.shared.showError("Please enter a friend ID or username")
            return
        }
        
        addError = nil
        isLoading = true
        
        Task {
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
            
            // Simulate potential error (15% chance for demo)
            if Int.random(in: 0..<100) < 15 {
                await MainActor.run {
                    self.addError = "Failed to add friend. Please try again."
                    self.isLoading = false
                }
                ToastManager.shared.showError("Failed to add friend. Please try again.")
                return
            }
            
            // Create a new mock friend from the input
            let newFriend = FriendMockModel(
                displayName: name.trimmingCharacters(in: .whitespaces),
                username: "@\(name.trimmingCharacters(in: .whitespaces).lowercased())"
            )
            
            await MainActor.run {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    self.friends.append(newFriend)
                    self.allFriends.append(newFriend)
                    self.showAddSuccess = true
                    self.isLoading = false
                }
                
                ToastManager.shared.showSuccess("Friend added successfully!")
                
                // Reset after showing success
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        self.showAddSuccess = false
                        self.addFriendText = ""
                        self.isShowingAddSheet = false
                    }
                }
            }
        }
    }
    
    func addFriend() {
        addFriend(addFriendText)
    }
    
    func removeFriend(_ friend: FriendMockModel) {
        isLoading = true
        
        Task {
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
            
            await MainActor.run {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    self.friends.removeAll { $0.id == friend.id }
                    self.allFriends.removeAll { $0.id == friend.id }
                    self.isLoading = false
                }
                ToastManager.shared.showSuccess("Friend removed")
            }
        }
    }
}
