import Foundation

public enum V0GoalCategory: String, CaseIterable, Codable, Hashable {
    case reading
    case exercise
    case meditation
    case writing
    case study
    case work
    case chores
    case cleaning
    case creative
    case music
    case finance
    case health
    case social
    case errands
    case learning
    case planning
    case sleep
    case other

    public var displayName: String {
        switch self {
        case .reading: return "Reading"
        case .exercise: return "Exercise"
        case .meditation: return "Meditation"
        case .writing: return "Writing"
        case .study: return "Study"
        case .work: return "Work"
        case .chores: return "Chores"
        case .cleaning: return "Cleaning"
        case .creative: return "Creative"
        case .music: return "Music"
        case .finance: return "Finance"
        case .health: return "Health"
        case .social: return "Social"
        case .errands: return "Errands"
        case .learning: return "Learning"
        case .planning: return "Planning"
        case .sleep: return "Sleep"
        case .other: return "Other"
        }
    }
}
