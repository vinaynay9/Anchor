import SwiftUI
import Shared

@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Step: Equatable {
        case intro
        case what
        case why
        case signUp
        case signIn
        case personalInfo
        case goalsFlow
    }

    @Published var currentStep: Step = .intro
    @Published var hasCompletedOnboarding: Bool = false

    private let userDefaults = UserDefaults.standard
    private let userService = UserService.shared
    private let logger = LoggerService.shared

    init() {
        hasCompletedOnboarding = userDefaults.bool(forKey: AppConfig.UserDefaultsKeys.hasCompletedOnboarding)
    }

    func markSeen() {
        userDefaults.set(true, forKey: AppConfig.UserDefaultsKeys.hasSeenOnboarding)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        userDefaults.set(true, forKey: AppConfig.UserDefaultsKeys.hasCompletedOnboarding)
    }

    func advance(to step: Step) {
        currentStep = step
    }

    func isPersonalInfoComplete(user: User?) -> Bool {
        if let user {
            let firstOk = !(user.firstName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let lastOk = !(user.lastName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let birthdayOk = !(user.birthday ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            if firstOk && lastOk && birthdayOk { return true }
        }
        return AppGroupStorage.shared.isPersonalInfoComplete()
    }

    func syncPersonalInfoIfAvailable(user: User?) {
        guard let user else { return }
        let first = (user.firstName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let last = (user.lastName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let birthday = (user.birthday ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !first.isEmpty, !last.isEmpty, !birthday.isEmpty else { return }
        AppGroupStorage.shared.setPersonalInfo(firstName: first, lastName: last, birthday: birthday)
    }

    func savePersonalInfo(firstName: String, lastName: String, birthday: Date) async -> Bool {
        let trimmedFirst = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLast = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFirst.isEmpty, !trimmedLast.isEmpty else { return false }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        let birthdayString = formatter.string(from: birthday)

        AppGroupStorage.shared.setPersonalInfo(firstName: trimmedFirst, lastName: trimmedLast, birthday: birthdayString)

        let displayName = "\(trimmedFirst) \(trimmedLast)".trimmingCharacters(in: .whitespacesAndNewlines)
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: birthday)
        let day = calendar.component(.day, from: birthday)
        AppGroupStorage.shared.setProfile(
            displayName: displayName,
            birthMonth: month,
            birthDay: day,
            timezone: TimeZone.current.identifier
        )

        do {
            _ = try await userService.updateUserProfile(
                displayName: displayName,
                birthMonth: month,
                birthDay: day,
                timezone: TimeZone.current.identifier,
                email: nil,
                firstName: trimmedFirst,
                lastName: trimmedLast,
                birthday: birthdayString
            )
            logger.logInfo("Personal info patch succeeded", category: "Auth")
            return true
        } catch {
            logger.logWarning("Personal info patch failed: \(error.localizedDescription)", category: "Auth")
            return false
        }
    }
}
