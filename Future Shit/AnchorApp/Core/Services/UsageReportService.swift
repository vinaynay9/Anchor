import Foundation
import Shared
#if canImport(FamilyControls)
import FamilyControls
#endif
#if canImport(DeviceActivity)
import DeviceActivity
#endif

// Lightweight local token used for usage reporting decoupled from FamilyControls
public struct ApplicationToken: Hashable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
}

// MARK: - Usage Report Models

struct AppUsageSummary: Identifiable {
    let id: String // bundle ID or token identifier
    let displayName: String
    let totalMinutes: Int
    let category: String
}

struct DayUsageSummary: Identifiable {
    let id: UUID
    let date: Date
    let totalMinutes: Int
}

// MARK: - Usage Report Errors

enum UsageReportError: LocalizedError {
    case authorizationDenied
    case authorizationNotDetermined
    case restrictedAccess
    case noDataAvailable
    case queryFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Screen Time authorization is required to view usage reports"
        case .authorizationNotDetermined:
            return "Screen Time authorization has not been requested"
        case .restrictedAccess:
            return "Access to usage reports is restricted"
        case .noDataAvailable:
            return "No usage data available for the selected period"
        case .queryFailed(let error):
            return "Failed to fetch usage data: \(error.localizedDescription)"
        }
    }
}

// MARK: - Usage Report Service

/// Service for fetching Screen Time usage reports using FamilyControls APIs
class UsageReportService {
    static let shared = UsageReportService()
    
    private let authorizationCenter = AuthorizationCenter.shared
    private let activitySelectionService = ActivitySelectionService.shared
    
    private init() {}
    
    // MARK: - Authorization Check
    
    private func checkAuthorization() throws {
        let status = authorizationCenter.authorizationStatus
        switch status {
        case .approved:
            return
        case .denied:
            throw UsageReportError.authorizationDenied
        case .notDetermined:
            throw UsageReportError.authorizationNotDetermined
        @unknown default:
            throw UsageReportError.authorizationNotDetermined
        }
    }
    
    // MARK: - Daily Usage Report
    
    /// Fetches daily usage summary grouped by app category
    /// - Returns: Array of AppUsageSummary sorted by total minutes (descending)
    func fetchDailyUsage() async throws -> [AppUsageSummary] {
        try checkAuthorization()
        
        Logger.info("UsageReportService: Fetching daily usage report", category: "UsageReport")
        
        // Get selected application tokens
        let tokens = activitySelectionService.loadApplicationTokens()
        
        guard !tokens.isEmpty else {
            Logger.warning("UsageReportService: No app tokens available, returning empty report", category: "UsageReport")
            return []
        }
        
        // Create event store
        let eventStore = EventStore()
        
        // Get today's date range
        let calendar = Calendar.current
        let now = Date()
        guard let startOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: now),
              let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) else {
            throw UsageReportError.queryFailed(NSError(domain: "UsageReportService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create date range"]))
        }
        
        let dateInterval = DateInterval(start: startOfDay, end: endOfDay)
        
        // Query events for selected applications
        do {
            let events = try await eventStore.queryEvents(
                for: dateInterval,
                filter: ActivityFilter(applicationTokens: Set(tokens))
            )
            
            // Group events by application token and calculate total minutes
            var usageByToken: [ApplicationToken: TimeInterval] = [:]
            
            for event in events {
                let duration = event.totalActivityDuration
                if let existing = usageByToken[event.applicationToken] {
                    usageByToken[event.applicationToken] = existing + duration
                } else {
                    usageByToken[event.applicationToken] = duration
                }
            }
            
            // Convert to AppUsageSummary
            var summaries: [AppUsageSummary] = []
            var index = 1
            
            for (token, duration) in usageByToken {
                let minutes = Int(duration / 60)
                
                // Note: ApplicationToken is privacy-preserving and doesn't expose app names directly
                // In a production app, you'd need to:
                // 1. Maintain a mapping of tokens to app names when user selects apps
                // 2. Use DeviceActivityReport extension for more detailed reporting
                // For now, we'll use generic names
                let displayName = "App \(index)"
                let category = categorizeUsage(minutes: minutes)
                
                summaries.append(AppUsageSummary(
                    id: String(token.hashValue),
                    displayName: displayName,
                    totalMinutes: minutes,
                    category: category
                ))
                index += 1
            }
            
            // Sort by total minutes descending
            summaries.sort { $0.totalMinutes > $1.totalMinutes }
            
            Logger.info("UsageReportService: Fetched \(summaries.count) app usage summaries", category: "UsageReport")
            
            return summaries
            
        } catch {
            Logger.error("UsageReportService: Failed to query events: \(error.localizedDescription)", category: "UsageReport")
            throw UsageReportError.queryFailed(error)
        }
    }
    
    // MARK: - Weekly Usage Report
    
    /// Fetches weekly usage summary (last 7 days)
    /// - Returns: Array of DayUsageSummary for each day of the week
    func fetchWeeklyUsage() async throws -> [DayUsageSummary] {
        try checkAuthorization()
        
        Logger.info("UsageReportService: Fetching weekly usage report", category: "UsageReport")
        
        // Get selected application tokens
        let tokens = activitySelectionService.loadApplicationTokens()
        
        guard !tokens.isEmpty else {
            Logger.warning("UsageReportService: No app tokens available, returning empty report", category: "UsageReport")
            return []
        }
        
        // Create event store
        let eventStore = EventStore()
        
        // Get date range for last 7 days
        let calendar = Calendar.current
        let now = Date()
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: now),
              let startOfWeek = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: sevenDaysAgo),
              let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) else {
            throw UsageReportError.queryFailed(NSError(domain: "UsageReportService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create date range"]))
        }
        
        let dateInterval = DateInterval(start: startOfWeek, end: endOfToday)
        
        // Query events for selected applications
        do {
            let events = try await eventStore.queryEvents(
                for: dateInterval,
                filter: ActivityFilter(applicationTokens: Set(tokens))
            )
            
            // Group events by day
            var usageByDay: [Date: TimeInterval] = [:]
            
            for event in events {
                let day = calendar.startOfDay(for: event.dateInterval.start)
                let duration = event.totalActivityDuration
                
                if let existing = usageByDay[day] {
                    usageByDay[day] = existing + duration
                } else {
                    usageByDay[day] = duration
                }
            }
            
            // Create DayUsageSummary for each day in the week
            var summaries: [DayUsageSummary] = []
            
            for dayOffset in 0..<7 {
                guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: now) else {
                    continue
                }
                let startOfDay = calendar.startOfDay(for: day)
                let minutes = Int((usageByDay[startOfDay] ?? 0) / 60)
                
                summaries.append(DayUsageSummary(
                    id: UUID(),
                    date: startOfDay,
                    totalMinutes: minutes
                ))
            }
            
            // Sort by date (oldest first)
            summaries.sort { $0.date < $1.date }
            
            Logger.info("UsageReportService: Fetched \(summaries.count) daily usage summaries", category: "UsageReport")
            
            return summaries
            
        } catch {
            Logger.error("UsageReportService: Failed to query events: \(error.localizedDescription)", category: "UsageReport")
            throw UsageReportError.queryFailed(error)
        }
    }
    
    // MARK: - Category-Based Daily Usage (Enhanced)
    
    /// Fetches daily usage grouped by app category
    /// This is a helper method that groups apps by category for better visualization
    func fetchDailyUsageByCategory() async throws -> [String: Int] {
        let summaries = try await fetchDailyUsage()
        
        var categoryUsage: [String: Int] = [:]
        
        for summary in summaries {
            let category = summary.category
            if let existing = categoryUsage[category] {
                categoryUsage[category] = existing + summary.totalMinutes
            } else {
                categoryUsage[category] = summary.totalMinutes
            }
        }
        
        return categoryUsage
    }
    
    // MARK: - Helper Methods
    
    /// Categorizes usage based on time spent (heuristic approach)
    /// In a real implementation, this would use actual app category data
    private func categorizeUsage(minutes: Int) -> String {
        // Simple heuristic: categorize based on usage patterns
        // In production, you'd maintain a mapping from ApplicationToken to AppCategory
        if minutes > 120 {
            return "High Usage"
        } else if minutes > 60 {
            return "Moderate Usage"
        } else if minutes > 30 {
            return "Low Usage"
        } else {
            return "Minimal Usage"
        }
    }
}

// MARK: - Local stubs for DeviceActivity event querying (compile-time fallback)

struct ActivityFilter {
    let applicationTokens: Set<ApplicationToken>
}

struct ActivityEvent {
    let applicationToken: ApplicationToken
    let totalActivityDuration: TimeInterval
    let dateInterval: DateInterval
}

final class EventStore {
    func queryEvents(for interval: DateInterval, filter: ActivityFilter) async throws -> [ActivityEvent] {
        // Placeholder implementation; real usage should use DeviceActivityReport extension.
        return []
    }
}

