import SwiftUI
import Combine

class OnboardingViewModel: ObservableObject {
    @Published var currentPage: Int = 0
    @Published var screenTimePermissionGranted: Bool = false
    @Published var notificationsPermissionGranted: Bool = false
    @Published var hasCompletedOnboarding: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    private let screenTimeService = ScreenTimeService.shared
    
    init() {
        // Load initial state from UserDefaults
        hasCompletedOnboarding = userDefaults.bool(forKey: hasCompletedOnboardingKey)
        
        // Check real permission statuses
        checkScreenTimePermission()
        checkNotificationsPermission()
    }
    
    var totalPages: Int {
        return 3
    }
    
    var isLastPage: Bool {
        return currentPage == totalPages - 1
    }
    
    func nextPage() {
        if currentPage < totalPages - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentPage += 1
            }
        }
    }
    
    func previousPage() {
        if currentPage > 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentPage -= 1
            }
        }
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        userDefaults.set(true, forKey: hasCompletedOnboardingKey)
    }
    
    // Real permission status checks
    func checkScreenTimePermission() {
        let status = screenTimeService.getAuthorizationStatus()
        screenTimePermissionGranted = (status == .approved)
    }
    
    func checkNotificationsPermission() {
        // TODO: Implement real notification permission check
        // For now, keep as false to indicate it needs to be requested
        notificationsPermissionGranted = false
    }
    
    /// Request Screen Time authorization
    func requestScreenTimePermission() async {
        do {
            try await screenTimeService.requestAuthorization()
            await MainActor.run {
                checkScreenTimePermission()
            }
        } catch {
            // Error handled by the service
            await MainActor.run {
                checkScreenTimePermission()
            }
        }
    }
}

