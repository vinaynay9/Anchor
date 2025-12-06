import Foundation
import Shared

protocol FriendActivityServiceProtocol {
    func fetchActivityFeed() async throws -> [FriendActivityEvent]
}

final class FriendActivityService: FriendActivityServiceProtocol {
    static let shared = FriendActivityService()
    
    private let apiClient: APIClient
    private let cacheKey = "friend_activity_feed_cache"
    private let cacheExpirationKey = "friend_activity_feed_cache_expiration"
    private let cacheExpirationInterval: TimeInterval = 300 // 5 minutes
    
    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }
    
    // MARK: - Fetch Activity Feed
    func fetchActivityFeed() async throws -> [FriendActivityEvent] {
        // Try to fetch from API first
        do {
            let dtos: [FriendActivityEventDTO] = try await apiClient.request(
                .getActivityFeed,
                responseType: [FriendActivityEventDTO].self
            )
            let events = dtos.compactMap { $0.toFriendActivityEvent() }
            
            // Cache the results
            cacheEvents(events)
            
            return events
        } catch {
            // If API fails, try to return cached data
            if let cachedEvents = getCachedEvents() {
                return cachedEvents
            }
            // If no cache available, throw the error
            throw error
        }
    }
    
    // MARK: - Caching
    
    private func cacheEvents(_ events: [FriendActivityEvent]) {
        guard let encoded = try? JSONEncoder().encode(events) else { return }
        
        UserDefaults.standard.set(encoded, forKey: cacheKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheExpirationKey)
    }
    
    private func getCachedEvents() -> [FriendActivityEvent]? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let expirationTimestamp = UserDefaults.standard.object(forKey: cacheExpirationKey) as? TimeInterval else {
            return nil
        }
        
        // Check if cache is still valid
        let expirationDate = Date(timeIntervalSince1970: expirationTimestamp)
        if Date() > expirationDate.addingTimeInterval(cacheExpirationInterval) {
            // Cache expired
            return nil
        }
        
        return try? JSONDecoder().decode([FriendActivityEvent].self, from: data)
    }
    
    // MARK: - Clear Cache
    
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheExpirationKey)
    }
}

