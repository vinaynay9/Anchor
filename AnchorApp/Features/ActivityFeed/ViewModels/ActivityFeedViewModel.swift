import Foundation
import SwiftUI
import Combine
import Shared

@MainActor
class ActivityFeedViewModel: ObservableObject {
    @Published var events: [FriendActivityEvent] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var friends: [Friend] = []
    
    private let activityService: FriendActivityServiceProtocol
    private let friendService: FriendServiceProtocol
    private var refreshTask: Task<Void, Never>?
    
    init(
        activityService: FriendActivityServiceProtocol = FriendActivityService.shared,
        friendService: FriendServiceProtocol = FriendService.shared
    ) {
        self.activityService = activityService
        self.friendService = friendService
    }
    
    // MARK: - Load Data
    
    func loadActivityFeed() {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        refreshTask?.cancel()
        refreshTask = Task {
            do {
                // Load friends first to get friend names
                async let friendsTask = friendService.getFriends()
                async let eventsTask = activityService.fetchActivityFeed()
                
                let (loadedFriends, loadedEvents) = try await (friendsTask, eventsTask)
                
                await MainActor.run {
                    self.friends = loadedFriends
                    // Sort events by timestamp (most recent first)
                    self.events = loadedEvents.sorted { $0.timestamp > $1.timestamp }
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
    
    func refreshActivityFeed() {
        loadActivityFeed()
    }
    
    // MARK: - Helper Methods
    
    func getFriendName(for friendId: String) -> String {
        guard let friendUUID = UUID(uuidString: friendId),
              let friend = friends.first(where: { $0.friendId == friendUUID }) else {
            return "Friend"
        }
        
        if let user = friend.friend {
            return user.displayName ?? user.username
        }
        
        return "Friend"
    }
    
    // MARK: - Grouped Events by Date
    
    struct GroupedEvent {
        let sectionTitle: String
        let events: [FriendActivityEvent]
    }
    
    var groupedEvents: [GroupedEvent] {
        let calendar = Calendar.current
        let now = Date()
        
        var groups: [GroupedEvent] = []
        var todayEvents: [FriendActivityEvent] = []
        var yesterdayEvents: [FriendActivityEvent] = []
        var thisWeekEvents: [FriendActivityEvent] = []
        var olderEvents: [FriendActivityEvent] = []
        
        for event in events {
            let daysAgo = calendar.dateComponents([.day], from: event.timestamp, to: now).day ?? 0
            
            if calendar.isDateInToday(event.timestamp) {
                todayEvents.append(event)
            } else if calendar.isDateInYesterday(event.timestamp) {
                yesterdayEvents.append(event)
            } else if daysAgo <= 7 {
                thisWeekEvents.append(event)
            } else {
                olderEvents.append(event)
            }
        }
        
        if !todayEvents.isEmpty {
            groups.append(GroupedEvent(sectionTitle: "Today", events: todayEvents))
        }
        if !yesterdayEvents.isEmpty {
            groups.append(GroupedEvent(sectionTitle: "Yesterday", events: yesterdayEvents))
        }
        if !thisWeekEvents.isEmpty {
            groups.append(GroupedEvent(sectionTitle: "This Week", events: thisWeekEvents))
        }
        if !olderEvents.isEmpty {
            groups.append(GroupedEvent(sectionTitle: "Earlier", events: olderEvents))
        }
        
        return groups
    }
    
    // MARK: - Event Type Helpers
    
    func getEventIcon(for type: FriendActivityType) -> String {
        switch type {
        case .proofSubmitted:
            return "camera.fill"
        case .unlockRequested:
            return "lock.open"
        case .unlockApproved:
            return "checkmark.circle.fill"
        case .sessionStarted:
            return "play.circle.fill"
        case .sessionCompleted:
            return "checkmark.circle"
        }
    }
    
    func getEventIconFallback() -> String {
        return "bell.fill" // Fallback icon for unknown types
    }
    
    func getEventColor(for type: FriendActivityType) -> Color {
        switch type {
        case .proofSubmitted:
            return AppColors.accent
        case .unlockRequested:
            return AppColors.warning
        case .unlockApproved:
            return AppColors.success
        case .sessionStarted:
            return AppColors.primary
        case .sessionCompleted:
            return AppColors.success
        }
    }
    
    func getEventColorFallback() -> Color {
        return AppColors.textSecondary // Fallback color for unknown types
    }
    
    func getEventTitle(for type: FriendActivityType, friendName: String) -> String {
        switch type {
        case .proofSubmitted:
            return "\(friendName) submitted a proof"
        case .unlockRequested:
            return "\(friendName) requested an unlock"
        case .unlockApproved:
            return "\(friendName) approved an unlock"
        case .sessionStarted:
            return "\(friendName) started a session"
        case .sessionCompleted:
            return "\(friendName) completed a session"
        }
    }
    
    func getEventTitleFallback(friendName: String) -> String {
        return "\(friendName) had activity" // Fallback title for unknown types
    }
    
    // MARK: - Validation
    
    /// Validates that events are sorted correctly (most recent first)
    func validateEventSorting() -> Bool {
        guard events.count > 1 else { return true }
        
        for i in 0..<events.count - 1 {
            if events[i].timestamp < events[i + 1].timestamp {
                return false
            }
        }
        return true
    }
    
    /// Validates that all events have valid friend IDs
    func validateEventFriendIds() -> Bool {
        let friendIds = Set(friends.map { $0.friendId.uuidString })
        return events.allSatisfy { friendIds.contains($0.friendId) || UUID(uuidString: $0.friendId) != nil }
    }
}

