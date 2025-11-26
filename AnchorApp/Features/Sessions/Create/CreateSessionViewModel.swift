import SwiftUI
import Foundation

@MainActor
class CreateSessionViewModel: ObservableObject {
    // Duration options in minutes
    let durationOptions: [Int] = [15, 30, 45, 60, 90, 120]
    
    @Published var selectedDuration: Int = 30
    @Published var selectedFriends: Set<String> = []
    
    // Mock friend list
    let mockFriends: [MockFriend] = [
        MockFriend(id: "1", name: "Alex"),
        MockFriend(id: "2", name: "Jordan"),
        MockFriend(id: "3", name: "Sam"),
        MockFriend(id: "4", name: "Taylor"),
        MockFriend(id: "5", name: "Casey")
    ]
    
    func toggleFriend(_ friendId: String) {
        if selectedFriends.contains(friendId) {
            selectedFriends.remove(friendId)
        } else {
            selectedFriends.insert(friendId)
        }
    }
    
    func startSession() {
        print("[CreateSessionViewModel] Starting session with duration: \(selectedDuration) minutes, friends: \(selectedFriends)")
    }
}

// Mock friend model for the standalone view
struct MockFriend: Identifiable {
    let id: String
    let name: String
}

