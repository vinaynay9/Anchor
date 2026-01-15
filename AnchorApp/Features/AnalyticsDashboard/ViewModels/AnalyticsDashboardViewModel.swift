import SwiftUI

@MainActor
final class AnalyticsDashboardViewModel: ObservableObject {
    @Published var selectedRange: AnalyticsRange = .last7Days {
        didSet { refresh() }
    }
    @Published private(set) var dashboardData: AnalyticsDashboardData?
    
    private let insightsService: AnalyticsInsightsService
    
    init(insightsService: AnalyticsInsightsService = .shared) {
        self.insightsService = insightsService
        refresh()
    }
    
    func refresh() {
        dashboardData = insightsService.buildDashboard(range: selectedRange)
    }
}
