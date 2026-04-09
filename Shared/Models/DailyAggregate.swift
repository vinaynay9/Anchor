import Foundation

/// Stores a single day's summarized stats, persisted locally in AppGroup.
/// Used by StatsView for averages, streaks, and top distractions.
/// Will sync to Supabase via AggregateService.syncAggregates() when connected.
public struct DailyAggregate: Codable, Hashable, Identifiable {
    public var id: String { date }  // date string is unique per day

    /// ISO date string "yyyy-MM-dd"
    public var date: String

    /// Total seconds the shield was active (locked) that day
    public var lockedSeconds: Int

    /// Number of goals completed
    public var goalsCompleted: Int

    /// Total goals that day
    public var goalsTotal: Int

    /// Number of times a blocked app was opened (shield hits)
    public var shieldHits: Int

    /// Shield hits broken down by category token label
    /// Key: human-readable category name (approximated), Value: hit count
    public var shieldHitsByCategory: [String: Int]

    public init(
        date: String,
        lockedSeconds: Int = 0,
        goalsCompleted: Int = 0,
        goalsTotal: Int = 0,
        shieldHits: Int = 0,
        shieldHitsByCategory: [String: Int] = [:]
    ) {
        self.date = date
        self.lockedSeconds = lockedSeconds
        self.goalsCompleted = goalsCompleted
        self.goalsTotal = goalsTotal
        self.shieldHits = shieldHits
        self.shieldHitsByCategory = shieldHitsByCategory
    }
}
