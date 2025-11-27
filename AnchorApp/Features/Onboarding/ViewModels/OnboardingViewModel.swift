import SwiftUI
import Combine

class OnboardingViewModel: ObservableObject {
    @Published var currentPage: Int = 0
    @Published var screenTimePermissionGranted: Bool = false
    @Published var notificationsPermissionGranted: Bool = false
    @Published var hasCompletedOnboarding: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    
    init() {
        // Load initial state from UserDefaults
        hasCompletedOnboarding = userDefaults.bool(forKey: hasCompletedOnboardingKey)
        
        // Mock permission statuses (no real API calls)
        // In a real app, these would check actual permission status
        screenTimePermissionGranted = false
        notificationsPermissionGranted = false
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
    
    // Mock methods for permission status (no real API calls)
    func checkScreenTimePermission() {
        // Mock: randomly set to true for demonstration
        // In real app, this would check actual Screen Time authorization
        screenTimePermissionGranted = Bool.random()
    }
    
    func checkNotificationsPermission() {
        // Mock: randomly set to true for demonstration
        // In real app, this would check actual notification authorization
        notificationsPermissionGranted = Bool.random()
    }
}

