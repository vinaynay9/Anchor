import Foundation
import SwiftUI
import Shared

@MainActor
class FriendsViewModel: ObservableObject {
    // MARK: - Published State
    @Published var friends: [Friend] = []
    @Published var friendRequests: [Friend] = []
    @Published var searchQuery: String = ""
    @Published var isShowingAddSheet = false
    @Published var addFriendText = ""
    @Published var showAddSuccess = false
    @Published var addError: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies (Protocol-based injection)
    private let friendService: FriendServiceProtocol
    
    // MARK: - Initialization
    
    init(friendService: FriendServiceProtocol = FriendService.shared) {
        self.friendService = friendService
    }
    
    // MARK: - Computed Properties
    
    var filteredFriends: [Friend] {
        if searchQuery.isEmpty {
            return friends
        }
        return friends.filter { friend in
            let displayName = friend.friend?.displayName ?? ""
            let username = friend.friend?.username ?? ""
            return displayName.localizedCaseInsensitiveContains(searchQuery) ||
                   username.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    // MARK: - Data Loading
    
    func loadFriends() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let loadedFriends = try await friendService.getFriends()
                self.friends = loadedFriends
                self.isLoading = false
            } catch {
                self.errorMessage = "Failed to load friends: \(error.localizedDescription)"
                self.isLoading = false
                ToastManager.shared.showError("Failed to load friends. Please try again.")
            }
        }
    }
    
    func loadFriendRequests() {
        Task {
            do {
                let requests = try await friendService.getFriendRequests()
                self.friendRequests = requests
            } catch {
                // Silently fail for friend requests - not critical
                print("Failed to load friend requests: \(error)")
            }
        }
    }
    
    // MARK: - Friend Management
    
    func addFriend(_ friendId: String) {
        guard !friendId.trimmingCharacters(in: .whitespaces).isEmpty else {
            withAnimation {
                addError = "Please enter a friend ID or username"
            }
            ToastManager.shared.showError("Please enter a friend ID or username")
            return
        }
        
        addError = nil
        isLoading = true
        
        Task {
            do {
                try await friendService.addFriend(friendId: friendId.trimmingCharacters(in: .whitespaces))
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    self.showAddSuccess = true
                    self.isLoading = false
                }
                
                ToastManager.shared.showSuccess("Friend request sent!")
                
                // Reload friends list
                loadFriends()
                
                // Reset after showing success
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        self.showAddSuccess = false
                        self.addFriendText = ""
                        self.isShowingAddSheet = false
                    }
                }
            } catch {
                self.addError = "Failed to add friend: \(error.localizedDescription)"
                self.isLoading = false
                ToastManager.shared.showError("Failed to add friend. Please try again.")
            }
        }
    }
    
    func addFriend() {
        addFriend(addFriendText)
    }
    
    func removeFriend(_ friend: Friend) {
        isLoading = true
        
        Task {
            do {
                try await friendService.deleteFriend(id: friend.id.uuidString)
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    self.friends.removeAll { $0.id == friend.id }
                    self.isLoading = false
                }
                ToastManager.shared.showSuccess("Friend removed")
            } catch {
                self.isLoading = false
                ToastManager.shared.showError("Failed to remove friend")
            }
        }
    }
    
    // MARK: - Friend Requests
    
    func acceptFriendRequest(_ request: Friend) {
        Task {
            do {
                try await friendService.acceptFriendRequest(id: request.id.uuidString)
                
                // Remove from requests and reload friends
                self.friendRequests.removeAll { $0.id == request.id }
                loadFriends()
                
                ToastManager.shared.showSuccess("Friend request accepted!")
            } catch {
                ToastManager.shared.showError("Failed to accept friend request")
            }
        }
    }
    
    func rejectFriendRequest(_ request: Friend) {
        Task {
            do {
                try await friendService.rejectFriendRequest(id: request.id.uuidString)
                
                // Remove from requests
                withAnimation {
                    self.friendRequests.removeAll { $0.id == request.id }
                }
                
                ToastManager.shared.showInfo("Friend request declined")
            } catch {
                ToastManager.shared.showError("Failed to decline friend request")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Gets the display name for a friend (from nested User object)
    func displayName(for friend: Friend) -> String {
        return friend.friend?.displayName ?? friend.friend?.username ?? "Unknown"
    }
    
    /// Gets the username for a friend (from nested User object)
    func username(for friend: Friend) -> String {
        return friend.friend?.username ?? ""
    }
    
    /// Gets initials for a friend
    func initials(for friend: Friend) -> String {
        let name = displayName(for: friend)
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1)) + String(components[1].prefix(1))
        }
        return String(name.prefix(2).uppercased())
    }
}
