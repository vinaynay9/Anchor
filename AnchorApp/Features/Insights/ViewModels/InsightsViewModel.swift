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
        
        do {
            if selectedTab == .daily {
                await loadDailyData()
            } else {
                await loadWeeklyData()
            }
        } catch {
            errorMessage = error.localizedDescription
            Logger.error("InsightsViewModel: Failed to load data: \(error.localizedDescription)", category: "Insights")
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

