import Foundation
import SwiftUI
import Shared

@MainActor
final class OnboardingState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    @Published var isSignedIn: Bool = false
    @Published var profileComplete: Bool = AppGroupStorage.shared.isProfileComplete()
    @Published var screenTimeGranted: Bool = false
    @Published var notificationsGranted: Bool = false

    func markProfileComplete() {
        profileComplete = true
    }

    func markScreenTimeGranted(_ granted: Bool) {
        screenTimeGranted = granted
    }

    func markNotificationsGranted(_ granted: Bool) {
        notificationsGranted = granted
    }
}

enum ProfileValidation {
    static func isValidBirthDate(month: Int, day: Int) -> Bool {
        Validation.isValidBirthDate(month: month, day: day)
    }
}
