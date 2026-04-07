import SwiftUI
import Combine
import Shared

@MainActor
class SessionViewModel: ObservableObject {
    @Published var activeSession: LockSession?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAnchored: Bool = false
    @Published var goalsCompleted: Int = 0
    @Published var goalsTotal: Int = 0
    @Published var usageSummaries: [AppUsageSummary] = []
    @Published var usageError: String?
    @Published var selectedDurationMinutes: Int = 25
    @Published var selectedCategories: Set<AppCategory> = []
    @Published var schedule: LockSessionSchedule? = nil
    
    private let sessionService: SessionServiceProtocol
    private let screenTimeService: ScreenTimeServiceProtocol
    private let dailyGoalService = DailyGoalService.shared
    private let usageReportService = UsageReportService.shared
    
    // Production default uses the real ScreenTimeService.
    // Pass MockScreenTimeService.shared explicitly in SwiftUI Previews or unit tests.
    init(
        sessionService: SessionServiceProtocol = SessionService.shared,
        screenTimeService: ScreenTimeServiceProtocol = ScreenTimeService.shared
    ) {
        self.sessionService = sessionService
        self.screenTimeService = screenTimeService
    }
    
    // MARK: - Notification Callbacks (UI-only wiring)
    
    /// Callback for when session ends - can be called from UI or notification handlers
    func onSessionEnded() {
        // Refresh active session state
        loadActiveSession()
        
        // Show UI feedback (toast will be shown by NotificationService if notifications disabled)
        // This is a UI-only callback for additional UI updates if needed
    }
    
    /// Callback for when session expires - can be called from UI or notification handlers
    func onSessionExpired() {
        // Refresh active session state
        loadActiveSession()
        
        // Show UI feedback (toast will be shown by NotificationService if notifications disabled)
        // This is a UI-only callback for additional UI updates if needed
    }
    
    func loadActiveSession() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                self.activeSession = try await sessionService.getActiveSession()
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func loadDashboardData() async {
        let shieldState = AppGroupStorage.shared.getShieldState()
        isAnchored = shieldState?.isBlocking ?? false

        let progress = dailyGoalService.loadProgress()
        goalsCompleted = progress.completedGoalIds.count
        goalsTotal = max((await dailyGoalService.loadGoals()).count, 0)

        do {
            usageSummaries = try await usageReportService.fetchDailyUsage()
            usageError = nil
        } catch {
            usageSummaries = []
            usageError = error.localizedDescription
        }
    }
    
    func startSession() async {
        isLoading = true
        errorMessage = nil
        
        // Check Screen Time authorization
        if !screenTimeService.isAuthorized() {
            // Request authorization if not already granted
            do {
                try await screenTimeService.requestAuthorization()
                
                // Verify authorization was granted
                if !screenTimeService.isAuthorized() {
                    self.errorMessage = "Screen Time authorization is required to enter Anchored Mode."
                    self.isLoading = false
                    return
                }
            } catch {
                self.errorMessage = "Failed to get Screen Time authorization: \(error.localizedDescription)"
                self.isLoading = false
                return
            }
        }
        
        // Authorization granted, proceed with starting session
        do {
            let categories = selectedCategories.isEmpty ? nil : Array(selectedCategories)
            let session = try await sessionService.startSession(
                durationMinutes: selectedDurationMinutes,
                friendIds: [],
                categories: categories,
                schedule: schedule
            )
            self.activeSession = session
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    func endSession() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await sessionService.endSession()
                self.activeSession = nil
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
