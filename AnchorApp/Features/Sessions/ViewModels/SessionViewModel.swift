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

    // MARK: - Timer (locked elapsed time)

    @Published var lockedElapsedSeconds: Int = 0
    private var timerCancellable: AnyCancellable?

    var lockedTimeDisplay: String {
        let h = lockedElapsedSeconds / 3600
        let m = (lockedElapsedSeconds % 3600) / 60
        let s = lockedElapsedSeconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    var shieldHitCountToday: Int {
        AppGroupStorage.shared.getShieldHitCountToday()
    }

    func startElapsedTimer(from startDate: Date) {
        stopElapsedTimer()
        let elapsed = max(0, Int(Date().timeIntervalSince(startDate)))
        lockedElapsedSeconds = elapsed
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.lockedElapsedSeconds += 1
            }
    }

    func stopElapsedTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

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

    func onSessionEnded() {
        loadActiveSession()
    }

    func onSessionExpired() {
        loadActiveSession()
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

        if isAnchored {
            let startDate = shieldState?.updatedAt ?? Date()
            startElapsedTimer(from: startDate)
        }

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

        if !screenTimeService.isAuthorized() {
            do {
                try await screenTimeService.requestAuthorization()
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
