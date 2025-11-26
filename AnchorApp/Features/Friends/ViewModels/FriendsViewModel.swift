import SwiftUI
import Combine

class FriendsViewModel: ObservableObject {
    @Published var friends: [Friend] = []
    @Published var pendingRequests: [Friend] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let friendService = FriendService.shared
    
    func loadFriends() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let loadedFriends = try await friendService.getFriends()
                await MainActor.run {
                    self.friends = loadedFriends
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func loadPendingRequests() {
        Task {
            do {
                let requests = try await friendService.getFriendRequests()
                await MainActor.run {
                    self.pendingRequests = requests
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func sendFriendRequest(friendId: UUID) {
        Task {
            do {
                try await friendService.addFriend(friendId: friendId.uuidString)
                await loadFriends()
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func acceptFriendRequest(requestId: UUID) {
        Task {
            do {
                try await friendService.acceptFriendRequest(id: requestId.uuidString)
                await loadFriends()
                await loadPendingRequests()
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

