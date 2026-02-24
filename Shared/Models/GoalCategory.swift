import Foundation

public enum GoalCategory: String, Codable, Hashable, CaseIterable {
    case fitness
    case health
    case mentalHealth
    case work
    case skillDevelopment
    case learning
    case school
    case career
    case finance
    case relationships
    case creativity
    case home
    case other

    public var displayName: String {
        switch self {
        case .fitness: return "Fitness"
        case .health: return "Health"
        case .mentalHealth: return "Mental Health"
        case .work: return "Work"
        case .skillDevelopment: return "Skill Development"
        case .learning: return "Learning"
        case .school: return "School"
        case .career: return "Career"
        case .finance: return "Finance"
        case .relationships: return "Relationships"
        case .creativity: return "Creative"
        case .home: return "Household"
        case .other: return "Other"
        }
    }
}
