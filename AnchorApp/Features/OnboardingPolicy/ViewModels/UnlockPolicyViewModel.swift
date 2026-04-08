import Foundation
import Shared

// MARK: - Reward Rules (Unlock Policy) View Model
// Drives the "How many goals to earn a break?" + "How much time per break?" step.
// Produces a UnlockPolicyConfig compatible with DailyGoalService.

@MainActor
final class UnlockPolicyViewModel: ObservableObject {

    // MARK: - Goals-per-break options

    enum GoalsThreshold: Hashable, CaseIterable {
        case one, two, three, all

        var displayName: String {
            switch self {
            case .one:   return "1 goal"
            case .two:   return "2 goals"
            case .three: return "3 goals"
            case .all:   return "All goals"
            }
        }

        /// Raw count — nil means "all".
        var count: Int? {
            switch self {
            case .one:   return 1
            case .two:   return 2
            case .three: return 3
            case .all:   return nil
            }
        }
    }

    // MARK: - Minutes-per-break options

    enum MinutesOption: Hashable, CaseIterable {
        case five, ten, fifteen, thirty, custom(Int)

        static var standardCases: [MinutesOption] { [.five, .ten, .fifteen, .thirty] }

        var displayName: String {
            switch self {
            case .five:         return "5 min"
            case .ten:          return "10 min"
            case .fifteen:      return "15 min"
            case .thirty:       return "30 min"
            case .custom(let m): return "\(m) min"
            }
        }

        var minutes: Int {
            switch self {
            case .five:         return 5
            case .ten:          return 10
            case .fifteen:      return 15
            case .thirty:       return 30
            case .custom(let m): return m
            }
        }

        var isCustom: Bool {
            if case .custom = self { return true }
            return false
        }
    }

    // MARK: - Published State

    @Published var selectedThreshold: GoalsThreshold = .one
    @Published var selectedMinutes: MinutesOption = .fifteen
    @Published var customMinutes: Int = 20    // only active when .custom is selected

    var isCustomSelected: Bool { selectedMinutes.isCustom }

    var isValid: Bool { effectiveMinutes > 0 }

    var effectiveMinutes: Int {
        isCustomSelected ? max(1, customMinutes) : selectedMinutes.minutes
    }

    // MARK: - Summary string shown at the bottom of the page

    var summaryText: String {
        let mins = effectiveMinutes
        let minsLabel = "\(mins) minute\(mins == 1 ? "" : "s")"

        switch selectedThreshold {
        case .all:
            return "Complete all your goals to fully unlock your apps for the rest of the day."
        default:
            let goalLabel = selectedThreshold.displayName
            return "For every \(goalLabel) you complete, you earn \(minsLabel) of screen time."
        }
    }

    // MARK: - Build UnlockPolicyConfig (Shared model used by DailyGoalService)

    func buildConfig() -> UnlockPolicyConfig {
        switch selectedThreshold {
        case .all:
            // "Complete all goals" maps to the existing unlockAppsWhenAllTasksDone mode.
            return UnlockPolicyConfig(mode: .unlockAppsWhenAllTasksDone)
        default:
            // Per-N-goals → unlockFixedTimePerGoal
            // The "goals per break" count is stored as percentStep (reusing the field
            // since UnlockPolicyConfig has no dedicated goalsPerBreak property).
            return UnlockPolicyConfig(
                mode: .unlockFixedTimePerGoal,
                timeIntervalMinutes: effectiveMinutes,
                percentStep: selectedThreshold.count
            )
        }
    }
}
