import Foundation
import SwiftUI
import Combine

@MainActor
class InsightsViewModel: ObservableObject {
    @Published var dailyUsage: [AppUsageSummary] = []
    @Published var weeklyUsage: [DayUsageSummary] = []
    @Published var categoryUsage: [String: Int] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedTab: InsightsTab = .daily
    
    private let usageReportService = UsageReportService.shared
    private var cancellables = Set<AnyCancellable>()
    
    enum InsightsTab {
        case daily
        case weekly
    }
    
    // MARK: - Computed Properties
    
    var topDistractingApps: [AppUsageSummary] {
        dailyUsage.prefix(5).map { $0 }
    }
    
    var weeklyTotalMinutes: Int {
        weeklyUsage.reduce(0) { $0 + $1.totalMinutes }
    }
    
    var currentStreak: Int {
        calculateStreak()
    }
    
    var hasData: Bool {
        !dailyUsage.isEmpty || !weeklyUsage.isEmpty
    }
    
    // MARK: - Initialization
    
    init() {
        // Load data on init
        Task {
            await loadData()
        }
    }
    
    // MARK: - Data Loading
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        if selectedTab == .daily {
            await loadDailyData()
        } else {
            await loadWeeklyData()
        }
        
        isLoading = false
    }
    
    private func loadDailyData() async {
        do {
            dailyUsage = try await usageReportService.fetchDailyUsage()
            categoryUsage = try await usageReportService.fetchDailyUsageByCategory()
        } catch {
            errorMessage = error.localizedDescription
            dailyUsage = []
            categoryUsage = [:]
        }
    }
    
    private func loadWeeklyData() async {
        do {
            weeklyUsage = try await usageReportService.fetchWeeklyUsage()
        } catch {
            errorMessage = error.localizedDescription
            weeklyUsage = []
        }
    }
    
    // MARK: - Tab Selection
    
    func selectTab(_ tab: InsightsTab) {
        guard selectedTab != tab else { return }
        
        selectedTab = tab
        
        Task {
            await loadData()
        }
    }
    
    // MARK: - Retry
    
    func retry() {
        Task {
            await loadData()
        }
    }
    
    // MARK: - Streak Calculation
    
    private func calculateStreak() -> Int {
        guard !weeklyUsage.isEmpty else { return 0 }
        
        // Calculate streak based on consecutive days with usage
        // Consider any day with > 0 minutes as active
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Sort days by date (most recent first)
        let sortedDays = weeklyUsage.sorted { $0.date > $1.date }
        
        var streak = 0
        var currentDate = today
        
        // Check today first
        if let todayUsage = sortedDays.first(where: { calendar.isDate($0.date, inSameDayAs: today) }),
           todayUsage.totalMinutes > 0 {
            streak = 1
            // Move to yesterday
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDate) {
                currentDate = calendar.startOfDay(for: yesterday)
            } else {
                return streak
            }
        } else {
            // If today has no usage, start from yesterday
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDate) {
                currentDate = calendar.startOfDay(for: yesterday)
            } else {
                return 0
            }
        }
        
        // Count consecutive days going backwards
        for dayOffset in 1..<7 {
            guard let checkDate = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                break
            }
            
            if let dayUsage = sortedDays.first(where: { calendar.isDate($0.date, inSameDayAs: checkDate) }) {
                if dayUsage.totalMinutes > 0 {
                    streak += 1
                } else {
                    break
                }
            } else {
                break
            }
        }
        
        return streak
    }
}
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
