import Foundation
import Shared

@MainActor
final class StatsViewModel: ObservableObject {
    // MARK: - Today

    @Published var todayLockedSeconds: Int = 0
    @Published var todayShieldHits: Int = 0
    @Published var todayGoalsCompleted: Int = 0
    @Published var todayGoalsTotal: Int = 0

    // MARK: - Averages (nil = less than 2 days of data)

    @Published var avgLockedSeconds: Double? = nil
    @Published var avgGoalsCompleted: Double? = nil
    @Published var avgShieldHits: Double? = nil

    // MARK: - Top categories

    @Published var topCategories: [(category: String, hits: Int)] = []

    // MARK: - Streaks

    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0

    private let aggregateService = AggregateService.shared
    private let storage = AppGroupStorage.shared
    private let dailyGoalService = DailyGoalService.shared

    // MARK: - Formatted helpers

    var todayLockedFormatted: String {
        let h = todayLockedSeconds / 3600
        let m = (todayLockedSeconds % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    var avgLockedFormatted: String {
        guard let avg = avgLockedSeconds else { return "--" }
        let h = Int(avg) / 3600
        let m = (Int(avg) % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    var avgGoalsFormatted: String {
        guard let avg = avgGoalsCompleted else { return "--" }
        return String(format: "%.1f", avg)
    }

    var avgShieldHitsFormatted: String {
        guard let avg = avgShieldHits else { return "--" }
        return String(format: "%.1f", avg)
    }

    var hasAnyData: Bool {
        todayGoalsTotal > 0 || todayLockedSeconds > 0
    }

    var topCategoryMax: Int {
        topCategories.first?.hits ?? 1
    }

    // MARK: - Load

    func load() async {
        // Today's live data
        let shieldState = storage.getShieldState()
        let isBlocking = shieldState?.isBlocking ?? false
        if isBlocking, let updatedAt = shieldState?.updatedAt {
            todayLockedSeconds = max(0, Int(Date().timeIntervalSince(updatedAt)))
        }

        todayShieldHits = storage.getShieldHitCountToday()

        let progress = storage.getDailyGoalProgress()
        todayGoalsCompleted = progress?.completedGoalIds.count ?? 0
        todayGoalsTotal = (await dailyGoalService.loadGoals()).count

        // Record a snapshot so today's data is reflected in averages
        await aggregateService.recordTodaySnapshot()

        // Averages
        avgLockedSeconds = aggregateService.averageLockedSeconds()
        avgGoalsCompleted = aggregateService.averageGoalsCompleted()
        avgShieldHits = aggregateService.averageShieldHits()

        // Top categories
        topCategories = aggregateService.topCategories()

        // Streaks
        currentStreak = aggregateService.currentStreak()
        longestStreak = aggregateService.longestStreak()

        // Trigger background sync (no-op until Supabase is connected)
        await aggregateService.syncAggregates()
    }
}
