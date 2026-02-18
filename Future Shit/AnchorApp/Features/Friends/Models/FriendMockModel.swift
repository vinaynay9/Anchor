import Foundation

struct FriendMockModel: Identifiable {
    let id: UUID
    let displayName: String
    let username: String
    
    init(id: UUID = UUID(), displayName: String, username: String) {
        self.id = id
        self.displayName = displayName
        self.username = username
    }
    
    var initials: String {
        let components = displayName.components(separatedBy: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1)) + String(components[1].prefix(1))
        }
        return String(displayName.prefix(2).uppercased())
    }
}

