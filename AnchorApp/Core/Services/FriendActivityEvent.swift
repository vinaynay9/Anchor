import Foundation
import Shared

// FriendActivityEvent, FriendActivityType, and FriendActivityEventDTO are defined in the Shared framework.
// Re-export them here as type aliases so AnchorApp code can use them without the module qualifier.
typealias FriendActivityEvent = Shared.FriendActivityEvent
typealias FriendActivityType = Shared.FriendActivityType
typealias FriendActivityEventDTO = Shared.FriendActivityEventDTO
