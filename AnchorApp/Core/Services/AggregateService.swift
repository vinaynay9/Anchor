import Foundation
import Shared

// MARK: - AggregateService
// Owns reading/writing DailyAggregates locally.
// syncAggregates() is structured for Supabase but not yet connected.
// Call recordTodaySnapshot() once at end of day (or on app background)
// to persist today's stats before midnight resets them.

@MainActor
final class AggregateService {
    static let shared = AggregateService()

    private let storage = AppGroupStorage.shared
    private let onboardingService = OnboardingService.shared

    private init() {}

    // MARK: - Local reads

    func getAllAggregates() -> [DailyAggregate] {
        storage.getAllDailyAggregates()
    }

    /// Current streak: consecutive days where goalsCompleted >= goalsTotal (and goalsTotal > 0).
    func currentStreak() -> Int {
        let aggs = storage.getAllDailyAggregates()
        guard !aggs.isEmpty else { return 0 }
        let sorted = aggs.sorted { $0.date > $1.date }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current

        var streak = 0
        var expected = Date()

        for agg in sorted {
            guard let aggDate = formatter.date(from: agg.date) else { continue }

            // Allow today or yesterday
            let dayDiff = Calendar.current.dateComponents([.day], from: aggDate, to: expected).day ?? 99
            if dayDiff > 1 { break }

            if agg.goalsTotal > 0 && agg.goalsCompleted >= agg.goalsTotal {
                streak += 1
                expected = aggDate
            } else {
                break
            }
        }
        return streak
    }

    /// Longest streak ever from stored aggregates.
    func longestStreak() -> Int {
        let aggs = storage.getAllDailyAggregates().sorted { $0.date < $1.date }
        var longest = 0
        var current = 0

        for agg in aggs {
            if agg.goalsTotal > 0 && agg.goalsCompleted >= agg.goalsTotal {
                current += 1
                longest = max(longest, current)
            } else {
                current = 0
            }
        }
        return longest
    }

    /// Average locked seconds per day (from days that have at least 1 goal).
    func averageLockedSeconds() -> Double? {
        let aggs = storage.getAllDailyAggregates().filter { $0.goalsTotal > 0 }
        guard aggs.count >= 2 else { return nil }
        let total = aggs.reduce(0) { $0 + $1.lockedSeconds }
        return Double(total) / Double(aggs.count)
    }

    func averageGoalsCompleted() -> Double? {
        let aggs = storage.getAllDailyAggregates().filter { $0.goalsTotal > 0 }
        guard aggs.count >= 2 else { return nil }
        let total = aggs.reduce(0) { $0 + $1.goalsCompleted }
        return Double(total) / Double(aggs.count)
    }

    func averageShieldHits() -> Double? {
        let aggs = storage.getAllDailyAggregates().filter { $0.goalsTotal > 0 }
        guard aggs.count >= 2 else { return nil }
        let total = aggs.reduce(0) { $0 + $1.shieldHits }
        return Double(total) / Double(aggs.count)
    }

    /// Aggregated shield hits per category across all days.
    func topCategories() -> [(category: String, hits: Int)] {
        var totals: [String: Int] = [:]
        for agg in storage.getAllDailyAggregates() {
            for (cat, hits) in agg.shieldHitsByCategory {
                totals[cat, default: 0] += hits
            }
        }
        return totals
            .map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 }
    }

    // MARK: - Snapshot (call at end of day or on app background)

    /// Reads today's live counters from AppGroupStorage and DailyGoalService,
    /// then persists them as a DailyAggregate.
    func recordTodaySnapshot() async {
        let today = localDayString(for: Date())
        var agg = DailyAggregate(date: today)

        // Goals
        let progress = storage.getDailyGoalProgress()
        let goals = await onboardingService.loadState().goals
        agg.goalsTotal = goals.count
        agg.goalsCompleted = progress?.completedGoalIds.count ?? 0

        // Shield hits
        agg.shieldHits = storage.getShieldHitCountToday()

        // Locked seconds: use shieldState.updatedAt as lock start if currently blocking
        if let shieldState = storage.getShieldState(), shieldState.isBlocking {
            let elapsed = Int(Date().timeIntervalSince(shieldState.updatedAt))
            agg.lockedSeconds = max(0, elapsed)
        }

        storage.saveDailyAggregate(agg)
    }

    // MARK: - Supabase sync (structured, not yet connected)

    /// Pushes all local DailyAggregates to Supabase.
    /// TODO: [Supabase Migration] Replace stub with real Supabase upsert.
    func syncAggregates() async {
        let aggregates = storage.getAllDailyAggregates()
        guard !aggregates.isEmpty else { return }

        let userId = UserDefaults.standard.string(forKey: AppConfig.UserDefaultsKeys.currentUserId)
        guard let userId else {
            LoggerService.shared.logInfo("syncAggregates: no userId, skipping", category: "AggregateService")
            return
        }

        // Delegate to SupabaseAggregatesService — no-op until SPM package is added.
        try? await SupabaseAggregatesService.shared.syncDailyAggregates(userId: userId, aggregates: aggregates)

        LoggerService.shared.logInfo(
            "syncAggregates — \(aggregates.count) records passed to SupabaseAggregatesService",
            category: "AggregateService"
        )
    }

    // MARK: - Helpers

    private func localDayString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
